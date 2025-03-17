import 'package:dio/dio.dart';

/// A base class for exceptions that may occur during HTTP requests/responses
/// when using the RestApiClient.
///
/// This class encapsulates error messages, a silent flag, and details
/// about the specific DioException that occurred, allowing for
/// better error handling and debugging.
class BaseException implements Exception {
  /// A flag indicating whether the exception should be silent or not.
  ///
  /// If set to true, the exception may be logged or reported in a way
  /// that does not interfere with the user experience.
  bool silent;

  /// A list of error messages associated with the exception.
  ///
  /// This can contain multiple messages to provide additional context
  /// about what went wrong.
  List<String> messages = [];

  /// An optional DioException that provides details about the original error
  /// thrown by the Dio HTTP client.
  DioException? exception;

  /// Creates a new instance of [BaseException].
  ///
  /// The [silent] parameter indicates whether the exception should be treated
  /// as silent. The [messages] parameter allows the user to provide a list
  /// of error messages, and the [exception] parameter can hold a DioException
  /// if available.
  BaseException({
    this.silent = false,
    this.messages = const [],
    this.exception,
  });

  /// Returns a string representation of the exception for debugging purposes.
  ///
  /// Includes the list of error messages for better insights into what
  /// went wrong.
  @override
  String toString() => 'BASE EXCEPTION: $messages';
}
