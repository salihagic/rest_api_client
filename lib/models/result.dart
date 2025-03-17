import 'package:rest_api_client/rest_api_client.dart';

/// A generic Result class to hold the outcome of operations.
class Result<T> {
  /// Holds the data returned from the operation.
  T? data;

  /// Holds additional error information, if any.
  dynamic errorData;

  /// The response object from the API call.
  Response? response;

  /// Exception if an error occurred.
  Exception? exception;

  /// HTTP status code for network operations.
  int? statusCode;

  /// HTTP status message for network operations.
  String? statusMessage;

  /// Checks if the result contains data.
  bool get hasData =>
      (data is List && (data as List).isNotEmpty) ||
      (data is! List && data != null);

  /// Determines if the result is successful (no errors).
  bool get isSuccess => !isError;

  /// Checks if the result is a local success.
  bool get isLocalSuccess => this is LocalSuccessResult;

  /// Checks if the result represents an error.
  bool get isError => exception != null;

  /// Checks if the result is a local error.
  bool get isLocalError => this is LocalErrorResult;

  /// Checks if the error is a connection error (specific to Dio exceptions).
  bool get isConnectionError =>
      (exception is DioException) &&
      (exception as DioException).type == DioExceptionType.connectionError;

  /// Constructor for creating a new Result instance.
  Result({
    this.data,
    this.errorData,
    this.response,
    this.exception,
    this.statusCode = 200,
    this.statusMessage = '',
  });

  /// Factory method to create a network result.
  factory Result.network({
    T? data,
    T? errorData,
    Response? response,
    Exception? exception,
    int? statusCode,
    String? statusMessage,
  }) =>
      NetworkResult(
        data: data,
        errorData: errorData,
        response: response,
        exception: exception,
        statusCode: statusCode,
        statusMessage: statusMessage,
      );

  /// Factory method to create a cache result.
  factory Result.cache({
    T? data,
    Exception? exception,
  }) =>
      CacheResult(
        data: data,
        exception: exception,
      );

  /// Factory method to create a success result.
  factory Result.success({
    T? data,
  }) =>
      SuccessResult(
        data: data,
      );

  /// Factory method to create a local success result.
  factory Result.localSuccess({
    T? data,
  }) =>
      LocalSuccessResult(
        data: data,
      );

  /// Factory method to create an error result.
  factory Result.error({
    Exception? exception,
  }) =>
      ErrorResult(
        exception: exception,
      );

  /// Factory method to create a local error result.
  factory Result.localError({
    Exception? exception,
  }) =>
      LocalErrorResult(
        exception: exception,
      );
}

/// Represents a successful result.
class SuccessResult<T> extends Result<T> {
  /// Constructor for a successful result.
  SuccessResult({super.data});
}

/// Represents a successful local (cached) result.
class LocalSuccessResult<T> extends Result<T> {
  /// Constructor for a successful local result.
  LocalSuccessResult({super.data});
}

/// Represents an error result.
class ErrorResult<T> extends Result<T> {
  /// Constructor for an error result.
  ErrorResult({
    super.exception,
    super.errorData,
  });
}

/// Represents a local error result (e.g., a caching error).
class LocalErrorResult<T> extends Result<T> {
  /// Constructor for a local error result.
  LocalErrorResult({
    super.exception,
    super.errorData,
  });
}

/// Represents a network result that includes the response.
class NetworkResult<T> extends Result<T> {
  /// Constructor for a network result.
  NetworkResult({
    super.data,
    super.errorData,
    super.response,
    super.exception,
    super.statusCode,
    super.statusMessage,
  });
}

/// Represents a result that comes from cache.
class CacheResult<T> extends Result<T> {
  /// Constructor for a cache result.
  CacheResult({super.data, super.exception});
}
