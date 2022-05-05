import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rest_api_client/constants/keys.dart';
import 'package:rest_api_client/implementations/default/auth_handler.dart';
import 'package:rest_api_client/implementations/default/exception_handler.dart';
import 'package:rest_api_client/interfaces/i_rest_api_client.dart';
import 'package:rest_api_client/models/result.dart';
import 'package:rest_api_client/options/exception_options.dart';
import 'package:rest_api_client/options/rest_api_client_options.dart';
import 'package:storage_repository/storage_repository.dart';

class RestApiClient implements IRestApiClient {
  late Dio _dio;
  late AuthHandler _authHandler;
  late ExceptionHandler _exceptionHandler;
  late IStorageRepository _secureStorage;
  late IStorageRepository _cacheStorage;

  final RestApiClientOptions options;
  late ExceptionOptions exceptionOptions;

  static Future<void> initFlutter() async => await StorageRepository.initFlutter();

  RestApiClient({
    required this.options,
    required this.exceptionOptions,
  }) {
    _secureStorage = SecureStorageRepository(key: RestApiClientKeys.storageKey, logPrefix: RestApiClientKeys.storageLogPrefix);
    _cacheStorage = StorageRepository(key: RestApiClientKeys.cachedStorageKey, logPrefix: RestApiClientKeys.cachedStorageLogPrefix);

    _dio = Dio(BaseOptions(baseUrl: options.baseUrl));
    _dio.httpClientAdapter = DefaultHttpClientAdapter();
    _authHandler = AuthHandler(dio: _dio, secureStorage: _secureStorage, options: options, exceptionOptions: exceptionOptions);
    _exceptionHandler = ExceptionHandler(exceptionOptions: exceptionOptions);

    _configureLogging();
    _addInterceptors();
    _configureCertificateOverride();
  }

  Future<IRestApiClient> init() async {
    await _secureStorage.init();
    if (options.loggingOptions.logStorage) await _secureStorage.log();

    await _cacheStorage.init();
    if (options.loggingOptions.logCacheStorage) await _cacheStorage.log();

    final jwt = await _secureStorage.get(RestApiClientKeys.jwt);
    if (jwt != null && jwt is String && jwt.isNotEmpty) _authHandler.setJwtToHeader(jwt);

    return this;
  }

  @override
  Future<Result<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future<Result<T>> getCached<T>(String path, {Map<String, dynamic>? queryParameters}) {
    // TODO: implement getCached
    throw UnimplementedError();
  }

  @override
  Stream<Result<T>> getStreamed<T>(String path, {Map<String, dynamic>? queryParameters}) {
    // TODO: implement getStreamed
    throw UnimplementedError();
  }

  @override
  Future<Result<T>> post<T>(String path, {data, Map<String, dynamic>? queryParameters}) {
    // TODO: implement post
    throw UnimplementedError();
  }

  @override
  Future<Result<T>> postCached<T>(String path, {data, Map<String, dynamic>? queryParameters}) {
    // TODO: implement postCached
    throw UnimplementedError();
  }

  @override
  Stream<Result<T>> postStreamed<T>(String path, {data, Map<String, dynamic>? queryParameters}) {
    // TODO: implement postStreamed
    throw UnimplementedError();
  }

  @override
  Future<Result<T>> put<T>(String path, {data, Map<String, dynamic>? queryParameters}) {
    // TODO: implement put
    throw UnimplementedError();
  }

  @override
  Future<Result<T>> head<T>(String path, {data, Map<String, dynamic>? queryParameters}) {
    // TODO: implement head
    throw UnimplementedError();
  }

  @override
  Future<Result<T>> delete<T>(String path, {data, Map<String, dynamic>? queryParameters}) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<Result<T>> patch<T>(String path, {data, Map<String, dynamic>? queryParameters}) {
    // TODO: implement patch
    throw UnimplementedError();
  }

  @override
  Future<Result> download(String urlPath, savePath, {data, Map<String, dynamic>? queryParameters}) {
    // TODO: implement download
    throw UnimplementedError();
  }

  @override
  Future clearStorage() async {
    await _secureStorage.clear();
    await _cacheStorage.clear();
  }

  Future _cacheResponse(Response response) async {
    final cacheKey = _generateCacheKey(response.requestOptions);

    await _cacheStorage.set(cacheKey, response.data);
  }

  Future<dynamic> _getDataFromCache(RequestOptions options) async {
    final cacheKey = _generateCacheKey(options);

    return await _cacheStorage.get(cacheKey);
  }

  String _generateCacheKey(RequestOptions options) {
    final String authorization = options.headers.containsKey(RestApiClientKeys.authorization) ? options.headers[RestApiClientKeys.authorization] : '';
    final queryParametersSerialized = options.queryParameters.isNotEmpty ? json.encode(options.queryParameters) : '';
    final dataSerialized = (options.data != null && options.data.isNotEmpty) ? json.encode(options.data) : '';

    final key = '$queryParametersSerialized$dataSerialized$authorization';

    return '${options.path} - ${md5.convert(utf8.encode(key)).toString()}';
  }

  void _configureLogging() {
    if (options.loggingOptions.logNetworkTraffic) {
      _dio.interceptors.add(
        PrettyDioLogger(
          responseBody: options.loggingOptions.responseBody,
          requestBody: options.loggingOptions.requestBody,
          requestHeader: options.loggingOptions.requestHeader,
          request: options.loggingOptions.request,
          responseHeader: options.loggingOptions.responseHeader,
          compact: options.loggingOptions.compact,
          error: options.loggingOptions.error,
        ),
      );
    }
  }

  void _addInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, handler) {
          options.extra.addAll({'showInternalServerErrors': exceptionOptions.showInternalServerErrors});
          options.extra.addAll({'showNetworkErrors': exceptionOptions.showNetworkErrors});
          options.extra.addAll({'showValidationErrors': exceptionOptions.showValidationErrors});

          return handler.next(options);
        },
        onResponse: (Response response, handler) {
          exceptionOptions.reset();

          return handler.next(response);
        },
        onError: (DioError error, handler) async {
          if (_authHandler.usesAutorization && error.response?.statusCode == HttpStatus.unauthorized) {
            return handler.resolve(await _authHandler.refreshTokenCallback(error));
          }

          await _exceptionHandler.handle(error, error.requestOptions.extra);

          return handler.next(error);
        },
      ),
    );
  }

  void _configureCertificateOverride() {
    if (options.overrideBadCertificate) {
      (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }
  }

  void setAcceptLanguageHeader(String languageCode) => _addOrUpdateHeader(key: RestApiClientKeys.acceptLanguage, value: languageCode);

  void _addOrUpdateHeader({required String key, required String value}) => _dio.options.headers.containsKey(key) ? _dio.options.headers.update(key, (v) => value) : _dio.options.headers.addAll({key: value});
}
