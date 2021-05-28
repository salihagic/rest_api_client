///Base class for any RestApiClient
///exception that might happen during
///http requests/responses
class BaseException implements Exception {
  ///Flag that represent if the exception should
  ///be silent
  bool silent;

  ///List of error messages
  List<String> messages = [];

  BaseException({
    this.silent = false,
    this.messages = const [],
  });

  ///Method to be called in debugging mode to
  ///check the contents of the exception
  @override
  String toString() => 'BASE EXCEPTION: ${this.messages}';
}
