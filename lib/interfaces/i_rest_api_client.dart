import 'package:rest_api_client/models/result.dart';

abstract class IRestApiClient {
  Future<Result<T>> get<T>(String path, {Map<String, dynamic>? queryParameters});
  Future<Result<T>> getCached<T>(String path, {Map<String, dynamic>? queryParameters});
  Stream<Result<T>> getStreamed<T>(String path, {Map<String, dynamic>? queryParameters});

  Future<Result<T>> post<T>(String path, {data, Map<String, dynamic>? queryParameters});
  Future<Result<T>> postCached<T>(String path, {data, Map<String, dynamic>? queryParameters});
  Stream<Result<T>> postStreamed<T>(String path, {data, Map<String, dynamic>? queryParameters});

  Future<Result<T>> put<T>(String path, {data, Map<String, dynamic>? queryParameters});

  Future<Result<T>> head<T>(String path, {data, Map<String, dynamic>? queryParameters});

  Future<Result<T>> delete<T>(String path, {data, Map<String, dynamic>? queryParameters});

  Future<Result<T>> patch<T>(String path, {data, Map<String, dynamic>? queryParameters});

  Future<Result> download(String urlPath, savePath, {data, Map<String, dynamic>? queryParameters});

  Future clearStorage();
}
