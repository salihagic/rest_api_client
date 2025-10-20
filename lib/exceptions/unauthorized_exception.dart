import 'package:rest_api_client/exceptions/base_exception.dart';

/// A derived exception class that represents unauthorized access errors
/// encountered during HTTP requests, typically indicating a 401 HTTP status code.
///
/// This class extends [BaseException] to specifically handle cases where
/// the request is not authorized, which may require user authentication
/// or authorization.
class UnauthorizedException extends BaseException {
  /// Creates a new instance of [UnauthorizedException].
  ///
  /// Optionally accepts parameters to specify if the exception should be
  /// silent, a list of messages explaining the reason for the unauthorized
  /// access, and any underlying DioException that provides further details
  /// regarding the authorization failure.
  UnauthorizedException({super.silent, super.messages, super.exception});

  /// Returns a string representation of the UnauthorizedException for debugging purposes.
  ///
  /// This method includes the list of error messages associated with the
  /// unauthorized access, making it easier for developers to diagnose issues
  /// related to user authentication or permissions.
  @override
  String toString() => 'UNAUTHORIZED EXCEPTION: $messages';
}
