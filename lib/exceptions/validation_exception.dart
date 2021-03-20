import 'rest_api_client_exception.dart';

class ValidationException extends RestApiClientException {
  late Map<String, List<String>> validationMessages;

  ValidationException({
    bool silent = false,
    List<String> messages = const [],
  }) : super(
          silent: silent,
          messages: messages,
        );

  ValidationException.multipleFields({
    bool silent = false,
    this.validationMessages = const {},
  }) : super(
          silent: silent,
          messages: validationMessages.entries
              .map<List<String>>((mapEntry) => mapEntry.value)
              .toList()
              .expand<String>((list) => list)
              .toList(),
        );

  @override
  String toString() => 'VALIDATION EXCEPTION: $messages';
}
