import 'package:rest_api_client/rest_api_client.dart';

///Derived exception class that represents
///any validation error
class ValidationException extends BaseException {
  Map<String, List<String>>? validationMessages;

  ValidationException({
    super.silent,
    super.messages,
    super.exception,
  });

  ///Constructon for creating validation
  ///messages list separated by property
  ValidationException.multipleFields({
    super.silent,
    this.validationMessages = const {},
    required DioException exception,
  }) : super(
          messages: validationMessages != null
              ? validationMessages.entries
                  .map<List<String>>(
                    (mapEntry) => mapEntry.value,
                  )
                  .toList()
                  .expand<String>((list) => list)
                  .toList()
              : [],
          exception: exception,
        );

  ///Method to be called in debugging mode to
  ///check the contents of the exception
  @override
  String toString() => 'VALIDATION EXCEPTION: $messages';
}
