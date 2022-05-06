import 'package:rest_api_client/models/result.dart';

abstract class IRestApiClient {
  Future<IRestApiClient> init();

  Future<Result<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, T Function(Map<String, dynamic> map)? parser});
  Future<Result<T>> getCached<T>(String path, {Map<String, dynamic>? queryParameters, T Function(Map<String, dynamic> map)? parser});
  Stream<Result<T>> getStreamed<T>(String path, {Map<String, dynamic>? queryParameters, T Function(Map<String, dynamic> map)? parser});

  Future<Result<T>> post<T>(String path, {data, Map<String, dynamic>? queryParameters, T Function(Map<String, dynamic> map)? parser});
  Future<Result<T>> postCached<T>(String path, {data, Map<String, dynamic>? queryParameters, T Function(Map<String, dynamic> map)? parser});
  Stream<Result<T>> postStreamed<T>(String path, {data, Map<String, dynamic>? queryParameters, T Function(Map<String, dynamic> map)? parser});

  Future<Result<T>> put<T>(String path, {data, Map<String, dynamic>? queryParameters, T Function(Map<String, dynamic> map)? parser});

  Future<Result<T>> head<T>(String path, {data, Map<String, dynamic>? queryParameters, T Function(Map<String, dynamic> map)? parser});

  Future<Result<T>> delete<T>(String path, {data, Map<String, dynamic>? queryParameters, T Function(Map<String, dynamic> map)? parser});

  Future<Result<T>> patch<T>(String path, {data, Map<String, dynamic>? queryParameters, T Function(Map<String, dynamic> map)? parser});

  Future<Result> download(String urlPath, savePath, {data, Map<String, dynamic>? queryParameters});

  void setContentType(String contentType);

  Future clearStorage();
}
