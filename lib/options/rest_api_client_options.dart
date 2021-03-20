class RestApiClientOptions {
  final String baseUrl;
  final bool logNetworkTraffic;
  final String refreshTokenEndpoint;
  final String refreshTokenParameterName;
  final String Function(dynamic response)? resolveJwt;
  final String Function(dynamic response)? resolveRefreshToken;
  final Map<String, List<String>> Function(dynamic response)? resolveValidationErrorsMap;

  RestApiClientOptions({
    this.baseUrl = '',
    this.logNetworkTraffic = true,
    this.refreshTokenEndpoint = '',
    this.refreshTokenParameterName = '',
    this.resolveJwt,
    this.resolveRefreshToken,
    this.resolveValidationErrorsMap,
  });
}
