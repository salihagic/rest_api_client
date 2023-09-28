import 'dart:async';

import 'package:rest_api_client/implementations/auth_handler.dart';
import 'package:rest_api_client/implementations/cache_handler.dart';
import 'package:rest_api_client/implementations/exception_handler.dart';
import 'package:rest_api_client/models/result.dart';
import 'package:rest_api_client/options/rest_api_client_request_options.dart';

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

  Future<Result> download(
    String urlPath,
    savePath, {
    data,
    Map<String, dynamic>? queryParameters,
    RestApiClientRequestOptions? options,
  });

  void setContentType(String contentType);
  void setAcceptLanguageHeader(String languageCode);
  void addOrUpdateHeader({required String key, required String value});

  Future clearStorage();
}
