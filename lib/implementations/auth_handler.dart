import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rest_api_client/constants/rest_api_client_keys.dart';
import 'package:rest_api_client/options/auth_options.dart';
import 'package:rest_api_client/options/exception_options.dart';
import 'package:rest_api_client/options/logging_options.dart';
import 'package:rest_api_client/options/rest_api_client_options.dart';
import 'package:storage_repository/storage_repository.dart';

class AuthHandler {
  final Dio dio;

  final RestApiClientOptions options;
  final AuthOptions authOptions;
  final ExceptionOptions exceptionOptions;
  final LoggingOptions loggingOptions;

  late StorageRepository _storage;

  AuthHandler({
    required this.dio,
    required this.options,
    required this.authOptions,
    required this.exceptionOptions,
    required this.loggingOptions,
  }) {
    _storage = authOptions.useSecureStorage
        ? SecureStorageRepositoryImpl(
            key: RestApiClientKeys.storageKey,
            logPrefix: RestApiClientKeys.storageLogPrefix,
          )
        : StorageRepositoryImpl(
            key: RestApiClientKeys.storageKey,
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
    if (currentJwt != null && currentJwt.isNotEmpty)
      _setJwtToHeader(currentJwt);
  }

  Future<bool> authorize(
      {required String jwt, required String refreshToken}) async {
    _addOrUpdateHeader(
        key: RestApiClientKeys.authorization, value: 'Bearer $jwt');

    return await _storage.set(RestApiClientKeys.jwt, jwt) &&
        await _storage.set(RestApiClientKeys.refreshToken, refreshToken);
  }

  Future<bool> unAuthorize() async {
    final deleteJwtResult = await _storage.delete(RestApiClientKeys.jwt);
    final deleteRefreshTokenResult =
        await _storage.delete(RestApiClientKeys.refreshToken);

    dio.options.headers.remove(RestApiClientKeys.authorization);

    return deleteJwtResult && deleteRefreshTokenResult;
  }

  /// Gets called when response status code is UnAuthorized and refreshes the token by calling specified refresh-token endpoint
  Future<Response<T>?> refreshTokenCallback<T>(DioException e) async {
    if (authOptions.resolveJwt != null &&
        authOptions.resolveRefreshToken != null) {
      await executeTokenRefresh();

      final currentJwt = await jwt;

      final requestOptions = e.requestOptions;

      //Set for current request
      if (requestOptions.headers.containsKey(RestApiClientKeys.authorization)) {
        requestOptions.headers.update(
            RestApiClientKeys.authorization, (v) => 'Bearer $currentJwt');
      } else {
        requestOptions.headers
            .addAll({RestApiClientKeys.authorization: 'Bearer $currentJwt'});
      }

      exceptionOptions.reset();

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
          receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
          followRedirects: requestOptions.followRedirects,
          maxRedirects: requestOptions.maxRedirects,
          requestEncoder: requestOptions.requestEncoder,
          responseDecoder: requestOptions.responseDecoder,
          listFormat: requestOptions.listFormat,
        ),
      );
    }

    return null;
  }

  /// Refreshes the token by calling specified refresh-token endpoint
  Future<void> executeTokenRefresh() async {
    final newDioClient = Dio(BaseOptions()
      ..baseUrl = options.baseUrl
      ..contentType = Headers.jsonContentType);

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

    final response = await newDioClient.post(
      authOptions.refreshTokenEndpoint,
      options: Options(
        headers: authOptions.refreshTokenHeadersBuilder
                ?.call(currentJwt ?? '', currentRefreshToken ?? '') ??
            {
              RestApiClientKeys.authorization: 'Bearer $currentJwt',
            },
      ),
      data: authOptions.refreshTokenBodyBuilder
              ?.call(currentJwt ?? '', currentRefreshToken ?? '') ??
          {
            authOptions.refreshTokenParameterName: currentRefreshToken,
          },
    );

    final resolvedJwt = authOptions.resolveJwt!(response);
    final resolvedRefreshToken = authOptions.resolveRefreshToken!(response);

    await authorize(jwt: resolvedJwt, refreshToken: resolvedRefreshToken);
  }

  Future clear() async {
    await _storage.clear();
  }

  void _setJwtToHeader(String jwt) async => _addOrUpdateHeader(
      key: RestApiClientKeys.authorization, value: 'Bearer $jwt');

  void _addOrUpdateHeader({required String key, required String value}) =>
      dio.options.headers.containsKey(key)
          ? dio.options.headers.update(key, (v) => value)
          : dio.options.headers.addAll({key: value});
}
