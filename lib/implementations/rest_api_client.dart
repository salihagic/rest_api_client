import 'dart:async';
import 'package:rest_api_client/rest_api_client.dart';
import 'package:storage_repository/storage_repository.dart';

abstract class RestApiClient {
  late AuthHandler authHandler;
  late ExceptionHandler exceptionHandler;
  late CacheHandler cacheHandler;
  Map<String, String> get headers;

  Future<RestApiClient> init();

  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
  });

  Future<Result<T>> getCached<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
  });

  Stream<Result<T>> getStreamed<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
  });

  Future<Result<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
    bool cacheEnabled = false,
  });

  Future<Result<T>> postCached<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
  });

  Stream<Result<T>> postStreamed<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
  });

  Future<Result<T>> put<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
  });

  Future<Result<T>> head<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
  });

  Future<Result<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
    RestApiClientRequestOptions? options,
  });

  Future<Result<T>> patch<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
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
    FutureOr<T> Function(dynamic data)? onSuccess,
    FutureOr<T> Function(dynamic data)? onError,
  });

  void setContentType(String contentType);
  void setAcceptLanguageHeader(String languageCode);
  void addOrUpdateHeader({required String key, required String value});

  Future<bool> authorize({required String jwt, required String refreshToken});

  Future<bool> unAuthorize();

  Future<bool> isAuthorized();

  Future clearStorage();

  static Future<void> initFlutter() async =>
      await StorageRepository.initFlutter();
}
