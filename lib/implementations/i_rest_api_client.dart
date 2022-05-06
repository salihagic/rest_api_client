import 'package:rest_api_client/implementations/auth_handler.dart';
import 'package:rest_api_client/implementations/cache_handler.dart';
import 'package:rest_api_client/implementations/exception_handler.dart';
import 'package:rest_api_client/models/result.dart';

abstract class IRestApiClient {
  late AuthHandler authHandler;
  late ExceptionHandler exceptionHandler;
  late CacheHandler cacheHandler;

  Future<IRestApiClient> init();

  Future<Result<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, T Function(dynamic data)? parser});
  Future<Result<T>> getCached<T>(String path, {Map<String, dynamic>? queryParameters, T Function(dynamic data)? parser});
  Stream<Result<T>> getStreamed<T>(String path, {Map<String, dynamic>? queryParameters, T Function(dynamic data)? parser});

  Future<Result<T>> post<T>(String path, {data, Map<String, dynamic>? queryParameters, T Function(dynamic data)? parser});
  Future<Result<T>> postCached<T>(String path, {data, Map<String, dynamic>? queryParameters, T Function(dynamic data)? parser});
  Stream<Result<T>> postStreamed<T>(String path, {data, Map<String, dynamic>? queryParameters, T Function(dynamic data)? parser});

  Future<Result<T>> put<T>(String path, {data, Map<String, dynamic>? queryParameters, T Function(dynamic data)? parser});

  Future<Result<T>> head<T>(String path, {data, Map<String, dynamic>? queryParameters, T Function(dynamic data)? parser});

  Future<Result<T>> delete<T>(String path, {data, Map<String, dynamic>? queryParameters, T Function(dynamic data)? parser});

  Future<Result<T>> patch<T>(String path, {data, Map<String, dynamic>? queryParameters, T Function(dynamic data)? parser});

  Future<Result> download(String urlPath, savePath, {data, Map<String, dynamic>? queryParameters});

  void setContentType(String contentType);
  void setAcceptLanguageHeader(String languageCode);

  Future clearStorage();
}
