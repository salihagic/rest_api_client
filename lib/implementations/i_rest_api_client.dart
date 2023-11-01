import 'dart:async';

import 'package:rest_api_client/implementations/auth_handler.dart';
import 'package:rest_api_client/implementations/cache_handler.dart';
import 'package:rest_api_client/implementations/exception_handler.dart';
import 'package:rest_api_client/rest_api_client.dart';

abstract class IRestApiClient {
  late AuthHandler authHandler;
  late ExceptionHandler exceptionHandler;
  late CacheHandler cacheHandler;

  Future<IRestApiClient> init();

  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? parser,
    RestApiClientRequestOptions? options,
  });

  Future<Result<T>> getCached<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? parser,
  });

  Stream<Result<T>> getStreamed<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? parser,
    RestApiClientRequestOptions? options,
  });

  Future<Result<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? parser,
    RestApiClientRequestOptions? options,
    bool cacheEnabled = false,
  });

  Future<Result<T>> postCached<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? parser,
  });

  Stream<Result<T>> postStreamed<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? parser,
    RestApiClientRequestOptions? options,
  });

  Future<Result<T>> put<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? parser,
    RestApiClientRequestOptions? options,
  });

  Future<Result<T>> head<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? parser,
    RestApiClientRequestOptions? options,
  });

  Future<Result<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? parser,
    RestApiClientRequestOptions? options,
  });

  Future<Result<T>> patch<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? parser,
    RestApiClientRequestOptions? options,
  });

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
    FutureOr<T> Function(dynamic data)? parser,
  });

  void setContentType(String contentType);
  void setAcceptLanguageHeader(String languageCode);
  void addOrUpdateHeader({required String key, required String value});

  Future clearStorage();
}
