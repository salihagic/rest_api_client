import 'package:rest_api_client/exceptions/base_exception.dart';

/// A derived exception class that represents network-related errors during
/// HTTP requests, such as connectivity issues or timeouts.
///
/// This class extends [BaseException] to specifically handle scenarios
/// where network errors occur, providing a clear distinction from other
/// types of errors, such as server or client errors.
class NetworkErrorException extends BaseException {
  /// Creates a new instance of [NetworkErrorException].
  ///
  /// Optionally accepts parameters to specify if the exception should be
  /// silent, a list of messages explaining the error, and any underlying
  /// DioException that provides further details about the network error.
  NetworkErrorException({super.silent, super.messages, super.exception});

  /// Returns a string representation of the NetworkErrorException for debugging purposes.
  ///
  /// This method includes the list of error messages related to the network error,
  /// aiding developers in diagnosing the issue.
  @override
  String toString() => 'NETWORK ERROR EXCEPTION: $messages';
}
