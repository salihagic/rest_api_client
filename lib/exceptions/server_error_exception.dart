import 'package:rest_api_client/exceptions/base_exception.dart';

/// A derived exception class that represents any server error encountered
/// during HTTP requests, typically indicating a 5xx HTTP status code.
///
/// This class extends [BaseException] to specifically handle errors that
/// originate from the server, distinguishing them from client and network
/// errors.
class ServerErrorException extends BaseException {
  /// Creates a new instance of [ServerErrorException].
  ///
  /// Optionally accepts parameters to specify if the exception should be
  /// silent, a list of messages explaining the server error, and any
  /// underlying DioException for further details about the server failure.
  ServerErrorException({
    super.silent,
    super.messages,
    super.exception,
  });

  /// Returns a string representation of the ServerErrorException for debugging purposes.
  ///
  /// This method includes the list of error messages associated with the server error,
  /// making it easier for developers to diagnose issues related to server responses.
  @override
  String toString() => 'SERVER ERROR EXCEPTION: $messages';
}
