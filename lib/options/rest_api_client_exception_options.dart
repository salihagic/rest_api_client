class RestApiClientExceptionOptions {
  bool showInternalServerErrors;
  bool showNetworkErrors;
  bool showValidationErrors;
  bool handleUnauthorizedError;
  bool handleForbiddenError;

  RestApiClientExceptionOptions({
    this.showInternalServerErrors = true,
    this.showNetworkErrors = true,
    this.showValidationErrors = true,
    this.handleUnauthorizedError = true,
    this.handleForbiddenError = true,
  }) {
    reset();
  }

  void reset() {
    showInternalServerErrors = true;
    showNetworkErrors = true;
    showValidationErrors = true;
    handleUnauthorizedError = false;
    handleForbiddenError = false;
  }

  //If this is called, error handling will be disabled only for the next request
  void disableErrorHandling() {
    showInternalServerErrors = false;
    showNetworkErrors = false;
    showValidationErrors = false;
    handleUnauthorizedError = false;
    handleForbiddenError = false;
  }
}
