import 'dart:async';
import 'dart:io';

import 'package:dio/io.dart';
import 'package:rest_api_client/implementations/refresh_token_interceptor.dart';
import 'package:rest_api_client/implementations/request_deduplication_interceptor.dart';
import 'package:rest_api_client/implementations/retry_interceptor.dart';
import 'package:rest_api_client/options/cache_options.dart';
import 'package:rest_api_client/options/rest_api_client_request_options.dart';
import 'package:rest_api_client/options/retry_options.dart';

import 'dio_adapter_stub.dart'
    if (dart.library.io) 'dio_adapter_mobile.dart'
    if (dart.library.js) 'dio_adapter_web.dart';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rest_api_client/constants/rest_api_client_keys.dart';
import 'package:rest_api_client/implementations/auth_handler.dart';
import 'package:rest_api_client/implementations/cache_handler.dart';
import 'package:rest_api_client/implementations/exception_handler.dart';
import 'package:rest_api_client/implementations/rest_api_client.dart';
import 'package:rest_api_client/models/result.dart';
import 'package:rest_api_client/options/auth_options.dart';
import 'package:rest_api_client/options/exception_options.dart';
import 'package:rest_api_client/options/logging_options.dart';
import 'package:rest_api_client/options/rest_api_client_options.dart';

/// Implementation of the [RestApiClient] interface using the Dio HTTP client.
///
/// This class provides a complete REST API client with support for:
/// - All standard HTTP methods (GET, POST, PUT, PATCH, DELETE, HEAD)
/// - JWT authentication with automatic token refresh
/// - Response caching with configurable lifetime
/// - Request retry with exponential backoff
/// - Request deduplication for concurrent identical requests
/// - File downloads with progress tracking
///
/// Example usage:
/// ```dart
/// final client = RestApiClientImpl(
///   options: RestApiClientOptions(baseUrl: 'https://api.example.com'),
///   authOptions: AuthOptions(
///     refreshTokenEndpoint: '/auth/refresh',
///     resolveJwt: (response) => response.data['access_token'],
///     resolveRefreshToken: (response) => response.data['refresh_token'],
///   ),
/// );
///
/// await client.init();
///
/// final result = await client.get<User>(
///   '/users/me',
///   onSuccess: (data) => User.fromJson(data),
/// );
///
/// if (result.hasData) {
///   print(result.data!.name);
/// }
/// ```
class RestApiClientImpl implements RestApiClient {
  /// The underlying Dio instance used for making HTTP requests.
  late Dio _dio;

  /// General client configuration (base URL, caching, certificates).
  late RestApiClientOptions _options;

  /// Configuration for exception handling and validation error parsing.
  late ExceptionOptions _exceptionOptions;

  /// Configuration for request/response logging.
  late LoggingOptions _loggingOptions;

  /// Configuration for JWT authentication and token refresh.
  late AuthOptions _authOptions;

  /// Configuration for response caching behavior.
  late CacheOptions _cacheOptions;

  /// Configuration for automatic request retry with backoff.
  late RetryOptions _retryOptions;

  /// Whether to deduplicate concurrent identical GET/HEAD requests.
  late bool _deduplicationEnabled;

  @override

  /// Handler for authentication operations (login, logout, token management).
  late AuthHandler authHandler;

  @override

  /// Handler for caching responses and retrieving cached data.
  late CacheHandler cacheHandler;

  @override

  /// Handler for processing and broadcasting exceptions.
  late ExceptionHandler exceptionHandler;

  /// Returns the current request headers as a string map.
  ///
  /// Useful for debugging or when you need to inspect the headers
  /// that will be sent with requests.
  @override
  Map<String, String> get headers =>
      _dio.options.headers.map((key, value) => MapEntry(key, value.toString()));

  /// Creates a new [RestApiClientImpl] instance.
  ///
  /// The [options] parameter is required and must include at least the base URL.
  /// All other parameters are optional and have sensible defaults.
  ///
  /// The [interceptors] parameter allows adding custom Dio interceptors that will
  /// be executed before the built-in refresh token and retry interceptors.
  RestApiClientImpl({
    required RestApiClientOptions options,
    ExceptionOptions? exceptionOptions,
    LoggingOptions? loggingOptions,
    AuthOptions? authOptions,
    CacheOptions? cacheOptions,
    RetryOptions? retryOptions,
    bool enableDeduplication = false,
    List<Interceptor> interceptors = const [],
  }) {
    _options = options; // Set client options
    _exceptionOptions =
        exceptionOptions ?? ExceptionOptions(); // Set exception options
    _loggingOptions =
        loggingOptions ?? const LoggingOptions(); // Set logging options
    _authOptions =
        authOptions ?? const AuthOptions(); // Set authentication options
    _cacheOptions = cacheOptions ?? const CacheOptions(); // Set cache options
    _retryOptions = retryOptions ?? const RetryOptions(); // Set retry options
    _deduplicationEnabled = enableDeduplication; // Set deduplication flag

    /// Initialize Dio with base URL
    _dio = Dio(BaseOptions(baseUrl: _options.baseUrl));

    /// Set the appropriate HTTP client adapter depending on the platform
    _dio.httpClientAdapter = getAdapter();

    // Initialize various handlers
    exceptionHandler = ExceptionHandler(exceptionOptions: _exceptionOptions);
    authHandler = AuthHandler(
      dio: _dio,
      options: options,
      exceptionOptions: _exceptionOptions,
      authOptions: _authOptions,
      loggingOptions: _loggingOptions,
      exceptionHandler: exceptionHandler,
    );
    cacheHandler = CacheHandler(
      loggingOptions: _loggingOptions,
      cacheOptions: _cacheOptions,
    );

    // Add custom interceptors
    _addInterceptors(interceptors);
    _configureLogging(); // Configure logging for requests/responses
    _configureCertificateOverride(); // Setup certificate overriding for development
  }

  /// Initializes the client and its handlers.
  ///
  /// This method must be called before making any requests. It initializes:
  /// - The authentication handler (restores stored tokens)
  /// - The cache handler (if caching is enabled)
  ///
  /// If [migrateFromHive] is `true` (default), attempts to migrate tokens
  /// from legacy Hive storage to the new storage format.
  ///
  /// Returns `this` for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final client = await RestApiClientImpl(options: options).init();
  /// ```
  @override
  Future<RestApiClient> init([bool migrateFromHive = true]) async {
    await authHandler.init(migrateFromHive);
    if (_options.cacheEnabled) {
      await cacheHandler.init();
    }
    return this;
  }

  /// Performs a GET request to the specified [path].
  ///
  /// Returns a [Result] containing either the successful response data or error information.
  ///
  /// Parameters:
  /// - [path]: The API endpoint path (relative to base URL)
  /// - [queryParameters]: Optional query string parameters
  /// - [onSuccess]: Optional callback to transform successful response data
  /// - [onError]: Optional callback to transform error response data
  /// - [options]: Per-request options (headers, auth requirements, etc.)
  /// - [cacheLifetimeDuration]: How long to cache the response (if caching enabled)
  ///
  /// The response is automatically cached if [RestApiClientOptions.cacheEnabled] is `true`.
  @override
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
    Duration? cacheLifetimeDuration,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options?.toOptions(),
      );

      if (_options.cacheEnabled) {
        await cacheHandler.set(response, cacheLifetimeDuration);
      }

      return NetworkResult(
        response: response,
        data: await _resolveResult(response.data, onSuccess),
      );
    } on DioException catch (e) {
      await exceptionHandler.handle(e, silent: options?.silentException);

      return NetworkResult(
        response: e.response,
        errorData: await _resolveResult(e.response?.data, onError),
        exception: e,
        statusCode: e.response?.statusCode,
        statusMessage: e.response?.statusMessage,
      );
    } catch (e) {
      debugPrint(e.toString());
      return Result.error(exception: Exception(e.toString()));
    }
  }

  /// Retrieves a cached response for the specified [path].
  ///
  /// Returns a [CacheResult] if cached data exists, otherwise returns an error result.
  /// This method does not make a network request.
  ///
  /// Use [getCachedOrNetwork] if you want to fall back to a network request
  /// when the cache misses.
  @override
  Future<Result<T>> getCached<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
  }) async {
    final requestOptions = RequestOptions(
      path: path,
      queryParameters: queryParameters,
      headers: _dio.options.headers,
    );

    try {
      return CacheResult(
        data: await _resolveResult(
          await cacheHandler.get(requestOptions),
          onSuccess,
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
      return Result.error(exception: Exception(e.toString()));
    }
  }

  /// Retrieves data from cache if available, otherwise makes a network request.
  ///
  /// This is a cache-first strategy: if valid cached data exists, it's returned
  /// immediately without making a network request. Otherwise, a GET request is made
  /// and the response is cached for future use.
  ///
  /// Useful for data that doesn't change frequently and where stale data is acceptable.
  @override
  Future<Result<T>> getCachedOrNetwork<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
    Duration? cacheLifetimeDuration,
  }) async {
    if (_options.cacheEnabled) {
      final cachedResult = await getCached(
        path,
        queryParameters: queryParameters,
        onSuccess: onSuccess,
      );

      if (cachedResult.hasData) {
        return cachedResult;
      }
    }

    return await get(
      path,
      queryParameters: queryParameters,
      onSuccess: onSuccess,
      options: options,
      cacheLifetimeDuration: cacheLifetimeDuration,
    );
  }

  /// Streams GET results, yielding cached data first (if available), then network data.
  ///
  /// This implements the stale-while-revalidate pattern: if cached data exists,
  /// it's yielded immediately for fast UI updates, then a network request is made
  /// and the fresh data is yielded as a second result.
  ///
  /// Useful for displaying cached data immediately while fetching updates in the background.
  ///
  /// Example:
  /// ```dart
  /// await for (final result in client.getStreamed<User>('/users/me')) {
  ///   if (result.hasData) {
  ///     updateUI(result.data!);
  ///   }
  /// }
  /// ```
  @override
  Stream<Result<T>> getStreamed<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
    Duration? cacheLifetimeDuration,
  }) async* {
    if (_options.cacheEnabled) {
      final cachedResult = await getCached(
        path,
        queryParameters: queryParameters,
        onSuccess: onSuccess,
      );

      if (cachedResult.hasData) {
        yield cachedResult;
      }
    }

    yield await get(
      path,
      queryParameters: queryParameters,
      onSuccess: onSuccess,
      options: options,
      cacheLifetimeDuration: cacheLifetimeDuration,
    );
  }

  /// Performs a POST request to the specified [path].
  ///
  /// Parameters:
  /// - [path]: The API endpoint path (relative to base URL)
  /// - [data]: The request body (can be Map, FormData, or any serializable object)
  /// - [queryParameters]: Optional query string parameters
  /// - [onSuccess]: Optional callback to transform successful response data
  /// - [onError]: Optional callback to transform error response data
  /// - [options]: Per-request options (headers, auth requirements, etc.)
  /// - [cacheEnabled]: Whether to cache this specific POST response (default: false)
  /// - [cacheLifetimeDuration]: How long to cache the response
  ///
  /// Note: POST responses are not cached by default since they typically modify data.
  /// Set [cacheEnabled] to `true` for read-only POST endpoints (e.g., search).
  @override
  Future<Result<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
    bool cacheEnabled = false,
    Duration? cacheLifetimeDuration,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options?.toOptions(),
      );

      if (cacheEnabled) {
        await cacheHandler.set(response, cacheLifetimeDuration);
      }

      return NetworkResult(
        response: response,
        data: await _resolveResult(response.data, onSuccess),
      );
    } on DioException catch (e) {
      await exceptionHandler.handle(e, silent: options?.silentException);

      return NetworkResult(
        response: e.response,
        exception: e,
        statusCode: e.response?.statusCode,
        statusMessage: e.response?.statusMessage,
      );
    } catch (e) {
      debugPrint(e.toString());
      return Result.error(exception: Exception(e.toString()));
    }
  }

  /// Retrieves a cached response for a POST request.
  ///
  /// The cache key is generated from the path, query parameters, request data,
  /// and headers. This method does not make a network request.
  ///
  /// Useful for caching search results or other read-only POST endpoints.
  @override
  Future<Result<T>> postCached<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
  }) async {
    final requestOptions = RequestOptions(
      path: path,
      queryParameters: queryParameters,
      data: data,
      headers: _dio.options.headers,
    );

    try {
      return CacheResult(
        data: await _resolveResult(
          await cacheHandler.get(requestOptions),
          onSuccess,
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
      return Result.error(exception: Exception(e.toString()));
    }
  }

  /// Streams POST results, yielding cached data first (if available), then network data.
  ///
  /// Similar to [getStreamed], implements the stale-while-revalidate pattern for POST requests.
  /// Cached data is yielded immediately, followed by fresh network data.
  @override
  Stream<Result<T>> postStreamed<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
    Duration? cacheLifetimeDuration,
  }) async* {
    if (_options.cacheEnabled) {
      final cachedResult = await postCached(
        path,
        queryParameters: queryParameters,
        data: data,
        onSuccess: onSuccess,
      );

      if (cachedResult.hasData) {
        yield cachedResult;
      }
    }

    yield await post(
      path,
      queryParameters: queryParameters,
      data: data,
      onSuccess: onSuccess,
      options: options,
      cacheLifetimeDuration: cacheLifetimeDuration,
    );
  }

  /// Performs a PUT request to the specified [path].
  ///
  /// PUT requests typically replace an entire resource at the given endpoint.
  /// Use [patch] for partial updates.
  @override
  Future<Result<T>> put<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        queryParameters: queryParameters,
        data: data,
        options: options?.toOptions(),
      );

      return NetworkResult(
        response: response,
        data: await _resolveResult(response.data, onSuccess),
      );
    } on DioException catch (e) {
      await exceptionHandler.handle(e, silent: options?.silentException);

      return NetworkResult(
        response: e.response,
        exception: e,
        statusCode: e.response?.statusCode,
        statusMessage: e.response?.statusMessage,
      );
    } catch (e) {
      debugPrint(e.toString());
      return Result.error(exception: Exception(e.toString()));
    }
  }

  /// Performs a HEAD request to the specified [path].
  ///
  /// HEAD requests are identical to GET but return only headers, not the body.
  /// Useful for checking if a resource exists or getting metadata without
  /// downloading the full content.
  @override
  Future<Result<T>> head<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
  }) async {
    try {
      final response = await _dio.head(
        path,
        queryParameters: queryParameters,
        data: data,
        options: options?.toOptions(),
      );

      return NetworkResult(
        response: response,
        data: await _resolveResult(response.data, onSuccess),
      );
    } on DioException catch (e) {
      await exceptionHandler.handle(e, silent: options?.silentException);

      return NetworkResult(
        response: e.response,
        exception: e,
        statusCode: e.response?.statusCode,
        statusMessage: e.response?.statusMessage,
      );
    } catch (e) {
      debugPrint(e.toString());
      return Result.error(exception: Exception(e.toString()));
    }
  }

  /// Performs a DELETE request to the specified [path].
  ///
  /// Used to delete a resource at the given endpoint.
  @override
  Future<Result<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
        data: data,
        options: options?.toOptions(),
      );

      return NetworkResult(
        response: response,
        data: await _resolveResult(response.data, onSuccess),
      );
    } on DioException catch (e) {
      await exceptionHandler.handle(e, silent: options?.silentException);

      return NetworkResult(
        response: e.response,
        exception: e,
        statusCode: e.response?.statusCode,
        statusMessage: e.response?.statusMessage,
      );
    } catch (e) {
      debugPrint(e.toString());
      return Result.error(exception: Exception(e.toString()));
    }
  }

  /// Performs a PATCH request to the specified [path].
  ///
  /// PATCH requests are used for partial updates to a resource.
  /// Use [put] if you need to replace the entire resource.
  @override
  Future<Result<T>> patch<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        queryParameters: queryParameters,
        data: data,
        options: options?.toOptions(),
      );

      return NetworkResult(
        response: response,
        data: await _resolveResult(response.data, onSuccess),
      );
    } on DioException catch (e) {
      await exceptionHandler.handle(e, silent: options?.silentException);

      return NetworkResult(
        response: e.response,
        exception: e,
        statusCode: e.response?.statusCode,
        statusMessage: e.response?.statusMessage,
      );
    } catch (e) {
      debugPrint(e.toString());
      return Result.error(exception: Exception(e.toString()));
    }
  }

  /// Downloads a file from the specified [urlPath] to [savePath].
  ///
  /// Parameters:
  /// - [urlPath]: The URL or path to download from
  /// - [savePath]: Local file path or a callback function `(Headers) => String`
  /// - [onReceiveProgress]: Callback for tracking download progress
  /// - [cancelToken]: Token to cancel the download
  /// - [deleteOnError]: Whether to delete the file if download fails (default: true)
  /// - [lengthHeader]: Header to read content length from
  ///
  /// Example:
  /// ```dart
  /// final result = await client.download(
  ///   '/files/document.pdf',
  ///   '/path/to/save/document.pdf',
  ///   onReceiveProgress: (received, total) {
  ///     print('${(received / total * 100).toStringAsFixed(0)}%');
  ///   },
  /// );
  /// ```
  @override
  Future<Result<T>> download<T>(
    String urlPath,
    savePath, {
    data,
    Map<String, dynamic>? queryParameters,
    RestApiClientRequestOptions? options,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
  }) async {
    try {
      final response = await _dio.download(
        urlPath,
        savePath,
        queryParameters: queryParameters,
        options: options?.toOptions(),
        data: data,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
      );

      return NetworkResult(
        response: response,
        data: await _resolveResult(response.data, onSuccess),
      );
    } on DioException catch (e) {
      await exceptionHandler.handle(e, silent: options?.silentException);

      return NetworkResult(
        response: e.response,
        exception: e,
        statusCode: e.response?.statusCode,
        statusMessage: e.response?.statusMessage,
      );
    } catch (e) {
      debugPrint(e.toString());
      return Result.error(exception: Exception(e.toString()));
    }
  }

  /// Sets the default Content-Type header for all requests.
  ///
  /// Common values: `application/json`, `application/x-www-form-urlencoded`,
  /// `multipart/form-data`.
  @override
  void setContentType(String contentType) =>
      _dio.options.contentType = contentType;

  /// Clears all stored authentication tokens and cached responses.
  ///
  /// Use this when the user logs out to ensure all sensitive data is removed.
  @override
  Future clearStorage() async {
    await authHandler.clear();
    if (_options.cacheEnabled) {
      await cacheHandler.clear();
    }
  }

  /// Configures the Dio logger interceptor based on [LoggingOptions].
  void _configureLogging() {
    if (_loggingOptions.logNetworkTraffic) {
      _dio.interceptors.add(
        PrettyDioLogger(
          responseBody: _loggingOptions.responseBody,
          requestBody: _loggingOptions.requestBody,
          requestHeader: _loggingOptions.requestHeader,
          request: _loggingOptions.request,
          responseHeader: _loggingOptions.responseHeader,
          compact: _loggingOptions.compact,
          error: _loggingOptions.error,
        ),
      );
    }
  }

  /// Configures the interceptor chain.
  ///
  /// Interceptor order:
  /// 1. Request deduplication (if enabled) - prevents duplicate concurrent requests
  /// 2. Custom interceptors (passed by user)
  /// 3. Refresh token interceptor - handles JWT refresh
  /// 4. Retry interceptor (if enabled) - retries failed requests
  void _addInterceptors(List<Interceptor> interceptors) {
    if (_deduplicationEnabled) {
      _dio.interceptors.add(RequestDeduplicationInterceptor());
    }

    _dio.interceptors.addAll(interceptors);

    _dio.interceptors.add(
      RefreshTokenInterceptor(
        authHandler: authHandler,
        exceptionHandler: exceptionHandler,
        exceptionOptions: _exceptionOptions,
        authOptions: _authOptions,
      ),
    );

    if (_retryOptions.enabled) {
      _dio.interceptors.add(
        RetryInterceptor(
          dio: _dio,
          retryOptions: _retryOptions,
        ),
      );
    }
  }

  /// Configures SSL certificate validation bypass for development.
  ///
  /// Only applies when [RestApiClientOptions.overrideBadCertificate] is `true`
  /// and the platform is not web. Use with caution in production.
  void _configureCertificateOverride() {
    if (_options.overrideBadCertificate && !kIsWeb) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }
  }

  /// Sets the Accept-Language header for localization.
  ///
  /// Use this to request localized responses from APIs that support it.
  @override
  void setAcceptLanguageHeader(String languageCode) => addOrUpdateHeader(
    key: RestApiClientKeys.acceptLanguage,
    value: languageCode,
  );

  /// Stores authentication tokens and sets up the Authorization header.
  ///
  /// Call this after a successful login to persist the user's session.
  /// Returns `true` if tokens were stored successfully.
  ///
  /// Example:
  /// ```dart
  /// final loginResult = await client.post('/auth/login', data: credentials);
  /// if (loginResult.hasData) {
  ///   await client.authorize(
  ///     jwt: loginResult.data!.accessToken,
  ///     refreshToken: loginResult.data!.refreshToken,
  ///   );
  /// }
  /// ```
  @override
  Future<bool> authorize({
    required String jwt,
    required String refreshToken,
  }) async {
    return await authHandler.authorize(jwt: jwt, refreshToken: refreshToken);
  }

  /// Clears stored tokens and removes the Authorization header.
  ///
  /// Call this when the user logs out to end their session.
  /// Returns `true` if tokens were cleared successfully.
  @override
  Future<bool> unAuthorize() async {
    return await authHandler.unAuthorize();
  }

  /// Checks if the user is currently authorized.
  ///
  /// Returns `true` if all of the following conditions are met:
  /// - Authorization header is set
  /// - JWT token exists in storage
  /// - Refresh token exists in storage
  @override
  Future<bool> isAuthorized() async {
    return await authHandler.isAuthorized;
  }

  /// Adds or updates a custom header for all requests.
  ///
  /// If the header already exists, its value is updated. Otherwise, a new
  /// header is added.
  @override
  void addOrUpdateHeader({required String key, required String value}) =>
      _dio.options.headers.containsKey(key)
      ? _dio.options.headers.update(key, (v) => value)
      : _dio.options.headers.addAll({key: value});

  /// Transforms response data using the provided callback.
  ///
  /// Returns `null` if either [data] or [callback] is null.
  FutureOr<T?> _resolveResult<T>(
    dynamic data, [
    FutureOr<T> Function(dynamic data)? callback,
  ]) async {
    if (data != null && callback != null) {
      return await callback(data);
    }
    return null;
  }
}
