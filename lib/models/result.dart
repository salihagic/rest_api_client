abstract class Result<T> {
  T? data;
  Exception? exception;
  bool get hasData => (data is List && (data as List).isNotEmpty) || (data is! List && data != null);
  bool get isSuccess => !isError;
  bool get isError => exception != null;
  int? statusCode;

  Result({
    this.data,
    this.exception,
    this.statusCode = 400,
  });
}

class NetworkResult<T> extends Result<T> {
  NetworkResult({T? data, Exception? exception, int? statusCode}) : super(data: data, exception: exception, statusCode: statusCode);
}

class CacheResult<T> extends Result<T> {
  CacheResult({T? data, Exception? exception, int? statusCode}) : super(data: data, exception: exception, statusCode: statusCode);
}
