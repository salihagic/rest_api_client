import 'rest_api_client_exception.dart';

class NetworkErrorException extends RestApiClientException {
  NetworkErrorException({
    bool silent = false,
    List<String> messages = const [],
  }) : super(
          silent: silent,
          messages: messages,
        );

  @override
  String toString() => 'NETWORK ERROR EXCEPTION: $messages';
}
