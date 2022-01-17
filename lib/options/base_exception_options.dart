///This class is part of exception handling
///mechanism implemented in RestApiClient
class BaseExceptionOptions {
  ///Toggle the value if you don't want to
  ///insert a new exception in exceptions stream
  ///from RestApiClient instance i the case of
  ///HttpStatus 500 in the response
  bool showInternalServerErrors;

  ///Toggle the value if you don't want to
  ///insert a new exception in exceptions stream
  ///from RestApiClient instance i the case of
  ///any network related errors
  bool showNetworkErrors;

  ///Toggle the value if you don't want to
  ///insert a new exception in exceptions stream
  ///from RestApiClient instance i the case of
  ///HttpStatus 400 in the response
  bool showValidationErrors;

  BaseExceptionOptions({
    this.showInternalServerErrors = true,
    this.showNetworkErrors = true,
    this.showValidationErrors = true,
  }) {
    reset();
  }

  ///This method resets this instance
  ///to a default state
  void reset() {
    showInternalServerErrors = true;
    showNetworkErrors = true;
    showValidationErrors = true;
  }

  ///If this is called, error handling
  ///will be disabled
  void disable() {
    showInternalServerErrors = false;
    showNetworkErrors = false;
    showValidationErrors = false;
  }
}
