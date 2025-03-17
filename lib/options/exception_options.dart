/// This class is part of the exception handling mechanism
/// implemented in the RestApiClient.
class ExceptionOptions {
  /// A function that resolves validation errors from the API response.
  ///
  /// The function takes a dynamic response as an input and
  /// returns a map where the keys are error field names
  /// and the values are lists of error messages associated with those fields.
  final Map<String, List<String>> Function(dynamic response)?
      resolveValidationErrorsMap;

  /// Constructor for creating an instance of ExceptionOptions.
  ///
  /// The optional parameter [resolveValidationErrorsMap] allows
  /// customization of how validation errors are extracted from
  /// the API response, supporting flexible validation error handling.
  ExceptionOptions({
    this.resolveValidationErrorsMap,
  });
}
