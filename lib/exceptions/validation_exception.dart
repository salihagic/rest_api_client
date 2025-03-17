import 'package:rest_api_client/rest_api_client.dart';

/// A derived exception class that represents any validation errors
/// encountered during API requests, typically related to improper data input.
class ValidationException extends BaseException {
  /// A map containing validation messages grouped by field names.
  Map<String, List<String>>? validationMessages;

  /// Creates a new instance of [ValidationException].
  ValidationException({
    super.silent,
    super.messages,
    super.exception,
  });

  /// Constructor for creating validation messages list separated by property.
  ///
  /// The [validationMessages] map provides validation errors for multiple fields,
  /// while the [exception] parameter provides the underlying exception details.
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

  /// Returns a string representation of the ValidationException for debugging purposes.
  @override
  String toString() => 'VALIDATION EXCEPTION: $messages';
}
