import 'dart:io';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rest_api_client/rest_api_client.dart';
import 'package:storage_repository/storage_repository.dart';

class AuthHandler {
  final Dio dio;
  final RestApiClientOptions options;
  final AuthOptions authOptions;
  final ExceptionOptions exceptionOptions;
  final LoggingOptions loggingOptions;
  final ExceptionHandler exceptionHandler;

  late StorageRepository _storage;

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
            logPrefix: RestApiClientKeys.storageLogPrefix,
          )
        : StorageRepositoryImpl(
            keyPrefix: RestApiClientKeys.storageKey,
            logPrefix: RestApiClientKeys.storageLogPrefix,
          );
  }

  Future<bool> get containsAuthorizationHeader async =>
      dio.options.headers.containsKey(RestApiClientKeys.authorization);
  Future<bool> get containsJwtInStorage async =>
      await _storage.contains(RestApiClientKeys.jwt);
  Future<bool> get containsRefreshTokenInStorage async =>
      await _storage.contains(RestApiClientKeys.refreshToken);
  Future<bool> get isAuthorized async =>
      await containsAuthorizationHeader &&
      await containsJwtInStorage &&
      await containsRefreshTokenInStorage;
  Future<String?> get jwt async => await _storage.get(RestApiClientKeys.jwt);
  Future<String?> get refreshToken async =>
      await _storage.get(RestApiClientKeys.refreshToken);
  bool get usesAuth =>
      dio.options.headers.containsKey(RestApiClientKeys.authorization);

  Future init() async {
    await _storage.init();

    if (loggingOptions.logStorage) {
      await _storage.log();
    }

    final currentJwt = await jwt;
    if (currentJwt != null && currentJwt.isNotEmpty) {
      _setJwtToHeader(currentJwt);
    }
  }

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

  Future<bool> unAuthorize() async {
    final deleteJwtResult = await _storage.delete(RestApiClientKeys.jwt);
    final deleteRefreshTokenResult = await _storage.delete(
      RestApiClientKeys.refreshToken,
    );

    dio.options.headers.remove(RestApiClientKeys.authorization);

    return deleteJwtResult && deleteRefreshTokenResult;
  }

  Future<Response<T>?> refreshTokenCallback<T>(
    RequestOptions requestOptions, [
    RequestInterceptorHandler? handler,
  ]) async {
    if (authOptions.resolveJwt != null &&
        authOptions.resolveRefreshToken != null) {
      await executeTokenRefresh(handler);

      final currentJwt = jwt;

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

  Future<void> executeTokenRefresh([RequestInterceptorHandler? handler]) async {
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

    final currentJwt = jwt;
    final currentRefreshToken = refreshToken;

    try {
      final response = await newDioClient.post(
        authOptions.refreshTokenEndpoint,
        options: Options(
          headers:
              authOptions.refreshTokenHeadersBuilder?.call(
                await currentJwt ?? '',
                await currentRefreshToken ?? '',
              ) ??
              {RestApiClientKeys.authorization: 'Bearer $currentJwt'},
        ),
        data:
            authOptions.refreshTokenBodyBuilder?.call(
              await currentJwt ?? '',
              await currentRefreshToken ?? '',
            ) ??
            {authOptions.refreshTokenParameterName: currentRefreshToken},
      );

      final resolvedJwt = authOptions.resolveJwt!(response);
      final resolvedRefreshToken = authOptions.resolveRefreshToken!(response);

      await authorize(jwt: resolvedJwt, refreshToken: resolvedRefreshToken);
    } on DioException catch (error) {
      await exceptionHandler.handle(error);

      handler?.next(error.requestOptions);
    }
  }

  Future clear() async {
    await _storage.clear();
  }

  void _setJwtToHeader(String jwt) => _addOrUpdateHeader(
    key: RestApiClientKeys.authorization,
    value: 'Bearer $jwt',
  );

  void _addOrUpdateHeader({required String key, required String value}) =>
      dio.options.headers.containsKey(key)
      ? dio.options.headers.update(key, (v) => value)
      : dio.options.headers.addAll({key: value});
}
