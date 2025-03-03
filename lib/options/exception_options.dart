///This class is part of exception handling
///mechanism implemented in RestApiClient
class ExceptionOptions {
  final Map<String, List<String>> Function(dynamic response)?
      resolveValidationErrorsMap;

  ExceptionOptions({
    this.resolveValidationErrorsMap,
  });
}
