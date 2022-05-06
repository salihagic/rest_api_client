import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:rest_api_client/constants/keys.dart';
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

  late IStorageRepository _storage;

  AuthHandler({
    required this.dio,
    required this.options,
    required this.authOptions,
    required this.exceptionOptions,
    required this.loggingOptions,
  }) {
    _storage = SecureStorageRepository(
      key: RestApiClientKeys.storageKey,
      logPrefix: RestApiClientKeys.storageLogPrefix,
    );
  }

  Future init() async {
    await _storage.init();

    if (loggingOptions.logStorage) {
      await _storage.log();
    }

    final jwt = await _storage.get(RestApiClientKeys.jwt);
    if (jwt != null && jwt is String && jwt.isNotEmpty) _setJwtToHeader(jwt);
  }

  bool get usesAutorization => dio.options.headers.containsKey(RestApiClientKeys.authorization);

  Future<bool> authorize({required String jwt, required String refreshToken}) async {
    _addOrUpdateHeader(key: RestApiClientKeys.authorization, value: 'Bearer $jwt');

    return await _storage.set(RestApiClientKeys.jwt, jwt) && await _storage.set(RestApiClientKeys.refreshToken, refreshToken);
  }

  Future<bool> unAuthorize() async {
    final deleteJwtResult = await _storage.delete(RestApiClientKeys.jwt);
    final deleteRefreshTokenResult = await _storage.delete(RestApiClientKeys.jwt);

    dio.options.headers.remove(RestApiClientKeys.authorization);

    return deleteJwtResult && deleteRefreshTokenResult;
  }

  Future<bool> isAuthorized() async {
    final containsAuthorizationHeader = dio.options.headers.containsKey(RestApiClientKeys.authorization);
    final containsJwtInStorage = await _storage.contains(RestApiClientKeys.jwt);
    final containsRefreshTokenInStorage = await _storage.contains(RestApiClientKeys.refreshToken);

    return containsAuthorizationHeader && containsJwtInStorage && containsRefreshTokenInStorage;
  }

  Future refreshTokenCallback(DioError error) async {
    try {
      if (authOptions.resolveJwt != null && authOptions.resolveRefreshToken != null) {
        // ignore: deprecated_member_use
        dio.interceptors.requestLock.lock();
        // ignore: deprecated_member_use
        dio.interceptors.responseLock.lock();

        final requestOptions = error.requestOptions;

        final newDioClient = Dio(BaseOptions()
          ..baseUrl = options.baseUrl
          ..contentType = Headers.jsonContentType);

        if (options.overrideBadCertificate) {
          (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
            client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
            return client;
          };
        }

        final response = await newDioClient.post(
          authOptions.refreshTokenEndpoint,
          data: {authOptions.refreshTokenParameterName: await _storage.get(RestApiClientKeys.refreshToken)},
        );

        final jwt = authOptions.resolveJwt!(response);
        final refreshToken = authOptions.resolveRefreshToken!(response);

        await authorize(jwt: jwt, refreshToken: refreshToken);

        //Set for current request
        if (requestOptions.headers.containsKey(RestApiClientKeys.authorization)) {
          requestOptions.headers.update(RestApiClientKeys.authorization, (v) => 'Bearer $jwt');
        } else {
          requestOptions.headers.addAll({RestApiClientKeys.authorization: 'Bearer $jwt'});
        }

        // ignore: deprecated_member_use
        dio.interceptors.requestLock.unlock();
        // ignore: deprecated_member_use
        dio.interceptors.responseLock.unlock();

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
    } catch (e) {
      // ignore: deprecated_member_use
      dio.interceptors.requestLock.unlock();
      // ignore: deprecated_member_use
      dio.interceptors.responseLock.unlock();

      throw e;
    }
  }

  Future clear() async {
    await _storage.clear();
  }

  void _setJwtToHeader(String jwt) async => _addOrUpdateHeader(key: RestApiClientKeys.authorization, value: 'Bearer $jwt');

  void _addOrUpdateHeader({required String key, required String value}) => dio.options.headers.containsKey(key) ? dio.options.headers.update(key, (v) => value) : dio.options.headers.addAll({key: value});
}
