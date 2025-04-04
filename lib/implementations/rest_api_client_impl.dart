import 'dart:async';
import 'dart:io';

import 'package:dio/io.dart';
import 'package:rest_api_client/implementations/refresh_token_interceptor.dart';
import 'package:rest_api_client/options/cache_options.dart';
import 'package:rest_api_client/options/rest_api_client_request_options.dart';

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

class RestApiClientImpl implements RestApiClient {
  /// Dio instance for making API requests
  late Dio _dio;

  /// Options for the REST API client
  late RestApiClientOptions _options;

  /// Options for error handling
  late ExceptionOptions _exceptionOptions;

  /// Options for logging network requests
  late LoggingOptions _loggingOptions;

  /// Options related to authentication
  late AuthOptions _authOptions;

  /// Options for caching data
  late CacheOptions _cacheOptions;

  @override

  /// Handler for managing authentication
  late AuthHandler authHandler;

  @override

  /// Handler for managing cache
  late CacheHandler cacheHandler;

  @override

  /// Handler for exceptions
  late ExceptionHandler exceptionHandler;

  /// Returns the headers from the Dio instance, converting values to strings.
  @override
  Map<String, String> get headers =>
      _dio.options.headers.map((key, value) => MapEntry(key, value.toString()));

  /// Constructor for initializing the RestApiClientImpl with required options and interceptors.
  RestApiClientImpl({
    required RestApiClientOptions options,
    ExceptionOptions? exceptionOptions,
    LoggingOptions? loggingOptions,
    AuthOptions? authOptions,
    CacheOptions? cacheOptions,
    List<Interceptor> interceptors = const [],
  }) {
    _options = options; // Set client options
    _exceptionOptions =
        exceptionOptions ?? ExceptionOptions(); // Set exception options
    _loggingOptions = loggingOptions ?? LoggingOptions(); // Set logging options
    _authOptions = authOptions ?? AuthOptions(); // Set authentication options
    _cacheOptions = cacheOptions ?? CacheOptions(); // Set cache options

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

  /// Initializes the client by preparing auth and cache handlers.
  @override
  Future<RestApiClient> init() async {
    await authHandler.init(); // Initialize authentication handler
    if (_options.cacheEnabled) {
      await cacheHandler
          .init(); // Initialize cache handler if caching is enabled
    }

    return this; // Return the client instance
  }

  /// Performs a GET request to the specified path with optional query parameters and callbacks.
  @override
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
  }) async {
    try {
      final response = await _dio.get(
        path, // The endpoint to hit
        queryParameters:
            queryParameters, // The parameters to send with the request
        options: options?.toOptions(), // Additional Dio options
      );

      // Cache response if caching is enabled
      if (_options.cacheEnabled) {
        await cacheHandler.set(response);
      }

      return NetworkResult(
        response: response,
        data: await _resolveResult(
            response.data, onSuccess), // Resolve result data
      );
    } on DioException catch (e) {
      await exceptionHandler.handle(e,
          silent: options?.silentException); // Handle Dio exceptions

      return NetworkResult(
        response: e.response, // Return error response
        errorData: await _resolveResult(
            e.response?.data, onError), // Resolve error data
        exception: e, // Return the exception
        statusCode: e.response?.statusCode, // HTTP status code
        statusMessage: e.response?.statusMessage, // HTTP status message
      );
    } catch (e) {
      debugPrint(e.toString()); // Print any other exceptions

      return Result.error(
          exception: Exception(e.toString())); // Return a generic error
    }
  }

  /// Performs a cached GET request to the specified path.
  @override
  Future<Result<T>> getCached<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
  }) async {
    final requestOptions = RequestOptions(
      path: path, // Path of the request
      queryParameters: queryParameters, // Query parameters
      headers: _dio.options.headers, // Request headers
    );

    try {
      return CacheResult(
        data: await _resolveResult(
          (await cacheHandler.get(requestOptions)), // Retrieve cached response
          onSuccess, // Success callback
        ),
      );
    } catch (e) {
      debugPrint(e.toString()); // Print any exceptions

      return Result.error(
          exception: Exception(e.toString())); // Return an error result
    }
  }

  /// Performs a streamed GET request to the specified path, optionally using cached data.
  @override
  Stream<Result<T>> getStreamed<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
  }) async* {
    // Check for cached result if caching is enabled.
    if (_options.cacheEnabled) {
      final cachedResult = await getCached(
        path,
        queryParameters: queryParameters,
        onSuccess: onSuccess,
      );

      if (cachedResult.hasData) {
        yield cachedResult; // Yield cached result
      }
    }

    yield await get(
      path, // Perform actual GET request
      queryParameters: queryParameters, // Query parameters for request
      onSuccess: onSuccess, // Optional success callback
      options: options, // Optional request options
    );
  }

  /// Performs a POST request to the specified path with optional data and query parameters.
  @override
  Future<Result<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
    bool cacheEnabled = false,
  }) async {
    try {
      final response = await _dio.post(
        path, // The endpoint to hit
        data: data, // Data to send in the request body
        queryParameters: queryParameters, // Query parameters
        options: options?.toOptions(), // Additional Dio options
      );

      // Cache response if caching is enabled
      if (cacheEnabled) {
        await cacheHandler.set(response);
      }

      return NetworkResult(
        response: response,
        data: await _resolveResult(
            response.data, onSuccess), // Resolve result data
      );
    } on DioException catch (e) {
      await exceptionHandler.handle(e,
          silent: options?.silentException); // Handle Dio exceptions

      return NetworkResult(
        response: e.response, // Return error response
        exception: e, // Return the exception
        statusCode: e.response?.statusCode, // HTTP status code
        statusMessage: e.response?.statusMessage, // HTTP status message
      );
    } catch (e) {
      debugPrint(e.toString()); // Print any exceptions

      return Result.error(
          exception: Exception(e.toString())); // Return a generic error
    }
  }

  /// Performs a cached POST request to the specified path.
  @override
  Future<Result<T>> postCached<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
  }) async {
    final requestOptions = RequestOptions(
      path: path, // Path of the request
      queryParameters: queryParameters, // Query parameters
      data: data, // Optional data in request body
      headers: _dio.options.headers, // Request headers
    );

    return CacheResult(
      data: await _resolveResult(
        (await cacheHandler.get(requestOptions)), // Retrieve cached response
        onSuccess, // Success callback
      ),
    );
  }

  /// Performs a streamed POST request to the specified path, optionally using cached data.
  @override
  Stream<Result<T>> postStreamed<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
  }) async* {
    // Check for cached result if caching is enabled.
    if (_options.cacheEnabled) {
      final cachedResult = await postCached(
        path,
        queryParameters: queryParameters,
        data: data,
        onSuccess: onSuccess,
      );

      if (cachedResult.hasData) {
        yield cachedResult; // Yield cached result
      }
    }

    yield await post(
      path, // Perform actual POST request
      queryParameters: queryParameters, // Query parameters for request
      data: data, // Data to send in the request body
      onSuccess: onSuccess, // Optional success callback
      options: options, // Optional request options
    );
  }

  /// Performs a PUT request to the specified path with optional data and query parameters.
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
        path, // The endpoint to hit
        queryParameters: queryParameters, // Query parameters
        data: data, // Data to send in the request body
        options: options?.toOptions(), // Additional Dio options
      );

      return NetworkResult(
        response: response,
        data: await _resolveResult(
            response.data, onSuccess), // Resolve result data
      );
    } on DioException catch (e) {
      await exceptionHandler.handle(e,
          silent: options?.silentException); // Handle Dio exceptions

      return NetworkResult(
        response: e.response, // Return error response
        exception: e, // Return the exception
        statusCode: e.response?.statusCode, // HTTP status code
        statusMessage: e.response?.statusMessage, // HTTP status message
      );
    } catch (e) {
      debugPrint(e.toString()); // Print any exceptions

      return Result.error(
          exception: Exception(e.toString())); // Return a generic error
    }
  }

  /// Performs a HEAD request to the specified path with optional data and query parameters.
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
        path, // The endpoint to hit
        queryParameters: queryParameters, // Query parameters
        data: data, // Optional data in request body
        options: options?.toOptions(), // Additional Dio options
      );

      return NetworkResult(
        response: response,
        data: await _resolveResult(
            response.data, onSuccess), // Resolve result data
      );
    } on DioException catch (e) {
      await exceptionHandler.handle(e,
          silent: options?.silentException); // Handle Dio exceptions

      return NetworkResult(
        response: e.response, // Return error response
        exception: e, // Return the exception
        statusCode: e.response?.statusCode, // HTTP status code
        statusMessage: e.response?.statusMessage, // HTTP status message
      );
    } catch (e) {
      debugPrint(e.toString()); // Print any exceptions

      return Result.error(
          exception: Exception(e.toString())); // Return a generic error
    }
  }

  /// Performs a DELETE request to the specified path with optional data and query parameters.
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
        queryParameters: queryParameters, // Query parameters
        data: data, // Data to send in the request body
        options: options?.toOptions(), // Additional Dio options
      );

      return NetworkResult(
        response: response,
        data: await _resolveResult(
            response.data, onSuccess), // Resolve result data
      );
    } on DioException catch (e) {
      await exceptionHandler.handle(e,
          silent: options?.silentException); // Handle Dio exceptions

      return NetworkResult(
        response: e.response, // Return error response
        exception: e, // Return the exception
        statusCode: e.response?.statusCode, // HTTP status code
        statusMessage: e.response?.statusMessage, // HTTP status message
      );
    } catch (e) {
      debugPrint(e.toString()); // Print any exceptions

      return Result.error(
          exception: Exception(e.toString())); // Return a generic error
    }
  }

  /// Performs a PATCH request to the specified path with optional data and query parameters.
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
        path, // The endpoint to hit
        queryParameters: queryParameters, // Query parameters
        data: data, // Data to send in the request body
        options: options?.toOptions(), // Additional Dio options
      );

      return NetworkResult(
        response: response,
        data: await _resolveResult(
            response.data, onSuccess), // Resolve result data
      );
    } on DioException catch (e) {
      await exceptionHandler.handle(e,
          silent: options?.silentException); // Handle Dio exceptions

      return NetworkResult(
        response: e.response, // Return error response
        exception: e, // Return the exception
        statusCode: e.response?.statusCode, // HTTP status code
        statusMessage: e.response?.statusMessage, // HTTP status message
      );
    } catch (e) {
      debugPrint(e.toString()); // Print any exceptions

      return Result.error(
          exception: Exception(e.toString())); // Return a generic error
    }
  }

  /// Downloads a file from the specified URL path to the save path.
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
        urlPath, // The URL path to download from
        savePath, // The local path to save the downloaded file
        queryParameters: queryParameters, // Query parameters
        options: options?.toOptions(), // Additional Dio options
        data: data, // Optional data in request body
        onReceiveProgress: onReceiveProgress, // Progress callback
        cancelToken: cancelToken, // Token to cancel the request
        deleteOnError: deleteOnError, // Flag to delete on error
        lengthHeader: lengthHeader, // Length header for response
      );

      return NetworkResult(
        response: response,
        data: await _resolveResult(
            response.data, onSuccess), // Resolve result data
      );
    } on DioException catch (e) {
      await exceptionHandler.handle(e,
          silent: options?.silentException); // Handle Dio exceptions

      return NetworkResult(
        response: e.response, // Return error response
        exception: e, // Return the exception
        statusCode: e.response?.statusCode, // HTTP status code
        statusMessage: e.response?.statusMessage, // HTTP status message
      );
    } catch (e) {
      debugPrint(e.toString()); // Print any exceptions

      return Result.error(
          exception: Exception(e.toString())); // Return a generic error
    }
  }

  /// Sets the content type for requests.
  @override
  void setContentType(String contentType) =>
      _dio.options.contentType = contentType;

  /// Clears authentication and cache storage.
  @override
  Future clearStorage() async {
    await authHandler.clear(); // Clear authentication data
    if (_options.cacheEnabled) {
      await cacheHandler.clear(); // Clear cache if enabled
    }
  }

  /// Configures logging options for Dio.
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

  /// Adds custom interceptors to Dio.
  void _addInterceptors(List<Interceptor> interceptors) {
    _dio.interceptors.addAll(interceptors); // Add custom interceptors

    _dio.interceptors.add(RefreshTokenInterceptor(
      authHandler: authHandler, // Add refresh token interceptor
      exceptionHandler: exceptionHandler,
      exceptionOptions: _exceptionOptions,
      authOptions: _authOptions,
    ));
  }

  /// Configures certificate overriding for development.
  void _configureCertificateOverride() {
    if (_options.overrideBadCertificate && !kIsWeb) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient(); // Create HttpClient instance

        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) =>
                true; // Override bad certificate

        return client; // Return the HttpClient
      };
    }
  }

  /// Sets the Accept-Language header in the request.
  @override
  void setAcceptLanguageHeader(String languageCode) => addOrUpdateHeader(
      key: RestApiClientKeys.acceptLanguage, value: languageCode);

  /// Authorizes the user with JWT and refresh token.
  @override
  Future<bool> authorize(
      {required String jwt, required String refreshToken}) async {
    return await authHandler.authorize(jwt: jwt, refreshToken: refreshToken);
  }

  /// Unauthorizes the user by clearing tokens.
  @override
  Future<bool> unAuthorize() async {
    return await authHandler.unAuthorize();
  }

  /// Checks if the user is authorized.
  @override
  Future<bool> isAuthorized() async {
    return await authHandler.isAuthorized; // Check authorization status
  }

  /// Adds or updates a header in the request.
  @override
  void addOrUpdateHeader({required String key, required String value}) =>
      _dio.options.headers.containsKey(key)
          ? _dio.options.headers.update(key, (v) => value)
          : _dio.options.headers.addAll({key: value});

  /// Resolves a result based on the data and optional success callback.
  FutureOr<T?> _resolveResult<T>(dynamic data,
      [FutureOr<T> Function(dynamic data)? onSuccess]) async {
    if (data != null && onSuccess != null) {
      return await onSuccess(data); // Call success callback
    } else {
      return null; // Return null if no data
    }
  }
}
