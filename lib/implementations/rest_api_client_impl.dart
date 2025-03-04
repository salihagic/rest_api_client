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
  late Dio _dio;

  late RestApiClientOptions _options;
  late ExceptionOptions _exceptionOptions;
  late LoggingOptions _loggingOptions;
  late AuthOptions _authOptions;
  late CacheOptions _cacheOptions;

  @override
  late AuthHandler authHandler;

  @override
  late CacheHandler cacheHandler;

  @override
  late ExceptionHandler exceptionHandler;

  @override
  Map<String, String> get headers =>
      _dio.options.headers.map((key, value) => MapEntry(key, value.toString()));

  RestApiClientImpl({
    required RestApiClientOptions options,
    ExceptionOptions? exceptionOptions,
    LoggingOptions? loggingOptions,
    AuthOptions? authOptions,
    CacheOptions? cacheOptions,
    List<Interceptor> interceptors = const [],
  }) {
    _options = options;
    _exceptionOptions = exceptionOptions ?? ExceptionOptions();
    _loggingOptions = loggingOptions ?? LoggingOptions();
    _authOptions = authOptions ?? AuthOptions();
    _cacheOptions = cacheOptions ?? CacheOptions();

    _dio = Dio(BaseOptions(baseUrl: _options.baseUrl));

    _dio.httpClientAdapter = getAdapter();

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
        loggingOptions: _loggingOptions, cacheOptions: _cacheOptions);

    _addInterceptors(interceptors);
    _configureLogging();
    _configureCertificateOverride();
  }

  Future<RestApiClient> init() async {
    await authHandler.init();
    if (_options.cacheEnabled) {
      await cacheHandler.init();
    }

    return this;
  }

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
        path,
        queryParameters: queryParameters,
        options: options?.toOptions(),
      );

      if (_options.cacheEnabled) {
        await cacheHandler.set(response);
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
          (await cacheHandler.get(requestOptions)),
          onSuccess,
        ),
      );
    } catch (e) {
      debugPrint(e.toString());

      return Result.error(exception: Exception(e.toString()));
    }
  }

  @override
  Stream<Result<T>> getStreamed<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
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
    );
  }

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
        path,
        data: data,
        queryParameters: queryParameters,
        options: options?.toOptions(),
      );

      if (cacheEnabled) {
        await cacheHandler.set(response);
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

    return CacheResult(
      data: await _resolveResult(
        (await cacheHandler.get(requestOptions)),
        onSuccess,
      ),
    );
  }

  @override
  Stream<Result<T>> postStreamed<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
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
    );
  }

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

  void setContentType(String contentType) =>
      _dio.options.contentType = contentType;

  @override
  Future clearStorage() async {
    await authHandler.clear();
    if (_options.cacheEnabled) {
      await cacheHandler.clear();
    }
  }

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

  void _addInterceptors(List<Interceptor> interceptors) {
    _dio.interceptors.addAll(interceptors);

    _dio.interceptors.add(RefreshTokenInterceptor(
      authHandler: authHandler,
      exceptionHandler: exceptionHandler,
      exceptionOptions: _exceptionOptions,
      authOptions: _authOptions,
    ));
  }

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

  void setAcceptLanguageHeader(String languageCode) => addOrUpdateHeader(
      key: RestApiClientKeys.acceptLanguage, value: languageCode);

  Future<bool> authorize(
      {required String jwt, required String refreshToken}) async {
    return await authHandler.authorize(jwt: jwt, refreshToken: refreshToken);
  }

  Future<bool> unAuthorize() async {
    return await authHandler.unAuthorize();
  }

  Future<bool> isAuthorized() async {
    return await authHandler.isAuthorized;
  }

  void addOrUpdateHeader({required String key, required String value}) =>
      _dio.options.headers.containsKey(key)
          ? _dio.options.headers.update(key, (v) => value)
          : _dio.options.headers.addAll({key: value});

  FutureOr<T?> _resolveResult<T>(dynamic data,
      [FutureOr<T> Function(dynamic data)? onSuccess]) async {
    if (data != null) {
      if (onSuccess != null) {
        return await onSuccess(data);
      } else {
        return data as T;
      }
    } else {
      return null;
    }
  }
}
