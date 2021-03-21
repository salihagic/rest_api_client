import 'rest_api_client_exception.dart';

///Derived exception class that represents
///any server error
class ServerErrorException extends RestApiClientException {
  ServerErrorException({
    bool silent = false,
    List<String> messages = const [],
  }) : super(
          silent: silent,
          messages: messages,
        );

  ///Method to be called in debugging mode to
  ///check the contents of the exception
  @override
  String toString() => 'NETWORK ERROR EXCEPTION: $messages';
}
