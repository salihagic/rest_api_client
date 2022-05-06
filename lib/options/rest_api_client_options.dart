class RestApiClientOptions {
  final String baseUrl;
  final bool overrideBadCertificate;
  final bool cacheEnabled;

  RestApiClientOptions({
    this.baseUrl = '',
    this.overrideBadCertificate = true,
    this.cacheEnabled = false,
  });
}
