class RestApiClientExceptionOptions {
  bool showInternalServerErrors;
  bool showNetworkErrors;
  bool showValidationErrors;

  RestApiClientExceptionOptions({
    this.showInternalServerErrors = true,
    this.showNetworkErrors = true,
    this.showValidationErrors = true,
  }) {
    reset();
  }

  void reset() {
    showInternalServerErrors = true;
    showNetworkErrors = true;
    showValidationErrors = true;
  }

  //If this is called, error handling will be disabled only for the next request
  void disableErrorHandling() {
    showInternalServerErrors = false;
    showNetworkErrors = false;
    showValidationErrors = false;
  }
}
