import 'dart:io';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rest_api_client/rest_api_client.dart';
import 'package:storage_repository/storage_repository.dart';

/// Handles JWT authentication, token storage, and automatic token refresh.
///
/// This class manages the complete authentication lifecycle including:
/// - Storing and retrieving JWT and refresh tokens securely
/// - Adding authorization headers to requests
/// - Refreshing expired tokens automatically
///
/// Example usage:
/// ```dart
/// // Authorize a user after login
/// await authHandler.authorize(jwt: accessToken, refreshToken: refreshToken);
///
/// // Check if user is authorized
/// if (await authHandler.isAuthorized) {
///   // User has valid tokens stored
/// }
///
/// // Logout - clear all tokens
/// await authHandler.unAuthorize();
/// ```
class AuthHandler {
  /// The Dio instance used for making HTTP requests.
  final Dio dio;

  /// General REST API client options (baseUrl, etc.).
  final RestApiClientOptions options;

  /// Authentication-specific options (refresh endpoint, token resolvers, etc.).
  final AuthOptions authOptions;

  /// Exception handling options.
  final ExceptionOptions exceptionOptions;

  /// Logging configuration options.
  final LoggingOptions loggingOptions;

  /// Handler for processing exceptions.
  final ExceptionHandler exceptionHandler;

  late StorageRepository _storage;

  /// Creates an AuthHandler instance.
  ///
  /// Automatically selects secure or regular storage based on [authOptions.useSecureStorage].
  AuthHandler({
    required this.dio,
    required this.options,
    required this.authOptions,
    required this.exceptionOptions,
    required this.loggingOptions,
    required this.exceptionHandler,
  }) {
    _storage = authOptions.useSecureStorage
        ? SecureStorageRepositoryImpl(
            keyPrefix: RestApiClientKeys.storageKey,
            migrationBoxKey: RestApiClientKeys.migration_storageKey,
          )
        : StorageRepositoryImpl(
            keyPrefix: RestApiClientKeys.storageKey,
            migrationBoxKey: RestApiClientKeys.migration_storageKey,
          );
  }

  /// Whether the Authorization header is currently set in Dio.
  Future<bool> get containsAuthorizationHeader async =>
      dio.options.headers.containsKey(RestApiClientKeys.authorization);

  /// Whether a JWT token exists in storage.
  Future<bool> get containsJwtInStorage async =>
      await _storage.contains(RestApiClientKeys.jwt);

  /// Whether a refresh token exists in storage.
  Future<bool> get containsRefreshTokenInStorage async =>
      await _storage.contains(RestApiClientKeys.refreshToken);

  /// Whether the user is fully authorized (has header, JWT, and refresh token).
  ///
  /// Returns `true` only if all three conditions are met:
  /// - Authorization header is set
  /// - JWT exists in storage
  /// - Refresh token exists in storage
  Future<bool> get isAuthorized async =>
      await containsAuthorizationHeader &&
      await containsJwtInStorage &&
      await containsRefreshTokenInStorage;

  /// Retrieves the stored JWT token, or `null` if not present.
  Future<String?> get jwt async => await _storage.get(RestApiClientKeys.jwt);

  /// Retrieves the stored refresh token, or `null` if not present.
  Future<String?> get refreshToken async =>
      await _storage.get(RestApiClientKeys.refreshToken);

  /// Whether the Dio instance currently has an Authorization header set.
  ///
  /// This is a synchronous check of the current header state.
  bool get usesAuth =>
      dio.options.headers.containsKey(RestApiClientKeys.authorization);

  /// Initializes the auth handler and restores any previously stored tokens.
  ///
  /// If [migrateFromHive] is `true`, attempts to migrate tokens from legacy Hive storage.
  /// After initialization, if a valid JWT exists in storage, it will be set to the
  /// Authorization header automatically.
  Future init([bool migrateFromHive = true]) async {
    await _storage.init(migrateFromHive);

    if (migrateFromHive) {
      await _migrateTokens();
    }

    if (loggingOptions.logStorage) {
      await _storage.log();
    }

    final currentJwt = await jwt;
    if (currentJwt != null && currentJwt.isNotEmpty) {
      _setJwtToHeader(currentJwt);
    }
  }

  /// Migrates tokens from legacy Hive storage keys to new storage keys.
  Future<void> _migrateTokens() async {
    final oldJwt = await _storage.get(RestApiClientKeys.migration_jwt);
    final oldRefreshToken = await _storage.get(
      RestApiClientKeys.migration_refreshToken,
    );

    if (!await _storage.contains(RestApiClientKeys.jwt) &&
        oldJwt != null &&
        oldJwt.isNotEmpty) {
      await _storage.set(RestApiClientKeys.jwt, oldJwt);
    }
    if (!await _storage.contains(RestApiClientKeys.refreshToken) &&
        oldRefreshToken != null &&
        oldRefreshToken.isNotEmpty) {
      await _storage.set(RestApiClientKeys.refreshToken, oldRefreshToken);
    }
  }

  /// Stores the JWT and refresh token, and sets the Authorization header.
  ///
  /// Call this after a successful login to persist the user's session.
  ///
  /// Returns `true` if both tokens were stored successfully.
  ///
  /// Example:
  /// ```dart
  /// final loginResponse = await api.login(email, password);
  /// await authHandler.authorize(
  ///   jwt: loginResponse.accessToken,
  ///   refreshToken: loginResponse.refreshToken,
  /// );
  /// ```
  Future<bool> authorize({
    required String jwt,
    required String refreshToken,
  }) async {
    _addOrUpdateHeader(
      key: RestApiClientKeys.authorization,
      value: 'Bearer $jwt',
    );

    return await _storage.set(RestApiClientKeys.jwt, jwt) &&
        await _storage.set(RestApiClientKeys.refreshToken, refreshToken);
  }

  /// Clears all stored tokens and removes the Authorization header.
  ///
  /// Call this when the user logs out to clear their session.
  ///
  /// Returns `true` if both tokens were deleted successfully.
  Future<bool> unAuthorize() async {
    final deleteJwtResult = await _storage.delete(RestApiClientKeys.jwt);
    final deleteRefreshTokenResult = await _storage.delete(
      RestApiClientKeys.refreshToken,
    );

    dio.options.headers.remove(RestApiClientKeys.authorization);

    return deleteJwtResult && deleteRefreshTokenResult;
  }

  /// Refreshes the token and retries the request with the new token.
  ///
  /// This is called by [RefreshTokenInterceptor] when a token refresh is needed.
  ///
  /// If [handler] is provided (from interceptor), it will call `handler.next()`
  /// to continue the interceptor chain. Otherwise, it executes the request
  /// directly and returns the response.
  ///
  /// Returns `null` if token resolvers are not configured.
  Future<Response<T>?> refreshTokenCallback<T>(
    RequestOptions requestOptions, [
    RequestInterceptorHandler? handler,
  ]) async {
    if (authOptions.resolveJwt != null &&
        authOptions.resolveRefreshToken != null) {
      await executeTokenRefresh();

      final currentJwt = await jwt;

      if (requestOptions.headers.containsKey(RestApiClientKeys.authorization)) {
        requestOptions.headers.update(
          RestApiClientKeys.authorization,
          (v) => 'Bearer $currentJwt',
        );
      } else {
        requestOptions.headers.addAll({
          RestApiClientKeys.authorization: 'Bearer $currentJwt',
        });
      }

      if (handler != null) {
        handler.next(requestOptions);
      } else {
        return await dio.request(
          requestOptions.path,
          cancelToken: requestOptions.cancelToken,
          data: requestOptions.data,
          onReceiveProgress: requestOptions.onReceiveProgress,
          onSendProgress: requestOptions.onSendProgress,
          queryParameters: requestOptions.queryParameters,
          options: Options(
            method: requestOptions.method,
            sendTimeout: requestOptions.sendTimeout,
            receiveTimeout: requestOptions.receiveTimeout,
            extra: requestOptions.extra,
            headers: requestOptions.headers,
            responseType: requestOptions.responseType,
            contentType: requestOptions.contentType,
            validateStatus: requestOptions.validateStatus,
            receiveDataWhenStatusError:
                requestOptions.receiveDataWhenStatusError,
            followRedirects: requestOptions.followRedirects,
            maxRedirects: requestOptions.maxRedirects,
            requestEncoder: requestOptions.requestEncoder,
            responseDecoder: requestOptions.responseDecoder,
            listFormat: requestOptions.listFormat,
          ),
        );
      }
    }

    return null;
  }

  /// Executes the token refresh request to the configured endpoint.
  ///
  /// Uses a separate Dio instance to avoid interceptor loops.
  /// On success, stores the new tokens via [authorize].
  /// On failure, handles the exception and rethrows.
  ///
  /// Throws [DioException] if the refresh request fails.
  Future<void> executeTokenRefresh() async {
    final newDioClient = Dio(
      BaseOptions()
        ..baseUrl = options.baseUrl
        ..contentType = Headers.jsonContentType,
    );

    if (loggingOptions.logNetworkTraffic) {
      newDioClient.interceptors.add(
        PrettyDioLogger(
          responseBody: loggingOptions.responseBody,
          requestBody: loggingOptions.requestBody,
          requestHeader: loggingOptions.requestHeader,
          request: loggingOptions.request,
          responseHeader: loggingOptions.responseHeader,
          compact: loggingOptions.compact,
          error: loggingOptions.error,
        ),
      );
    }

    if (options.overrideBadCertificate && !kIsWeb) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();

        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

        return client;
      };
    }

    final currentJwt = await jwt;
    final currentRefreshToken = await refreshToken;

    try {
      final response = await newDioClient.post(
        authOptions.refreshTokenEndpoint,
        options: Options(
          headers:
              authOptions.refreshTokenHeadersBuilder?.call(
                currentJwt ?? '',
                currentRefreshToken ?? '',
              ) ??
              {RestApiClientKeys.authorization: 'Bearer $currentJwt'},
        ),
        data:
            authOptions.refreshTokenBodyBuilder?.call(
              currentJwt ?? '',
              currentRefreshToken ?? '',
            ) ??
            {authOptions.refreshTokenParameterName: currentRefreshToken},
      );

      final resolvedJwt = authOptions.resolveJwt!(response);
      final resolvedRefreshToken = authOptions.resolveRefreshToken!(response);

      await authorize(jwt: resolvedJwt, refreshToken: resolvedRefreshToken);
    } on DioException catch (error) {
      await exceptionHandler.handle(error);

      rethrow;
    }
  }

  /// Clears all data from the auth storage.
  ///
  /// This removes all stored tokens. Use [unAuthorize] instead if you also
  /// want to remove the Authorization header.
  Future clear() async {
    await _storage.clear();
  }

  /// Sets the JWT to the Authorization header.
  void _setJwtToHeader(String jwt) => _addOrUpdateHeader(
    key: RestApiClientKeys.authorization,
    value: 'Bearer $jwt',
  );

  /// Adds or updates a header in the Dio instance.
  void _addOrUpdateHeader({required String key, required String value}) =>
      dio.options.headers.containsKey(key)
      ? dio.options.headers.update(key, (v) => value)
      : dio.options.headers.addAll({key: value});
}
