import 'package:rest_api_client/exceptions/base_exception.dart';

/// A derived exception class that represents a server error when access is forbidden,
/// typically indicating a 403 HTTP status code.
///
/// This class extends the [BaseException] and is used to handle cases where a
/// client attempts to access a resource they do not have permission to view.
class ForbiddenException extends BaseException {
  /// Creates a new instance of [ForbiddenException].
  ///
  /// Optionally accepts parameters to control whether the exception is silent,
  /// a list of error messages, and an underlying DioException for further details.
  ForbiddenException({super.silent, super.messages, super.exception});

  /// Returns a string representation of the ForbiddenException for debugging purposes.
  ///
  /// This method includes the list of error messages related to the forbidden access
  /// attempt, making it easier to diagnose the issue.
  @override
  String toString() => 'FORBIDDEN EXCEPTION: $messages';
}
