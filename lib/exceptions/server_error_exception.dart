import 'rest_api_client_exception.dart';

class ServerErrorException extends RestApiClientException {
  ServerErrorException({
    bool silent = false,
    List<String> messages = const [],
  }) : super(
          silent: silent,
          messages: messages,
        );

  @override
  String toString() => 'NETWORK ERROR EXCEPTION: $messages';
}
