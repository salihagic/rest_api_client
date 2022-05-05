abstract class Result<T> {
  T? data;
  Exception? exception;
  bool get hasData => (data is List && (data as List).isNotEmpty) || (data is! List && data != null);
  bool get isSuccess => !isError;
  bool get isError => exception != null;

  Result({this.data, this.exception});
}

class NetworkResult<T> extends Result<T> {
  NetworkResult({T? data, Exception? exception}) : super(data: data, exception: exception);
}

class CacheResult<T> extends Result<T> {
  CacheResult({T? data, Exception? exception}) : super(data: data, exception: exception);
}
