/// Options to configure the RestApiClient.
class RestApiClientOptions {
  /// The base URL for API requests.
  ///
  /// This URL serves as the foundation for all API endpoints
  /// used by the RestApiClient. It should be specified when
  /// initializing the client.
  final String baseUrl;

  /// Toggle to override bad SSL certificates.
  ///
  /// If set to true, the client will ignore SSL certificate
  /// validation errors. This is useful for testing environments
  /// with self-signed certificates. However, it should be used
  /// with caution in production environments as it can expose
  /// the application to security risks.
  final bool overrideBadCertificate;

  /// Toggle to enable or disable cache.
  ///
  /// If set to true, caching will be enabled for API responses,
  /// improving performance by reducing the number of network
  /// requests. When false, all requests will be made directly
  /// to the API server.
  final bool cacheEnabled;

  /// Timeout for establishing a connection to the server.
  ///
  /// If a connection is not established within this duration,
  /// a [DioException] with type [DioExceptionType.connectionTimeout] will be thrown.
  /// When null, no timeout is applied.
  final Duration? connectTimeout;

  /// Default timeout for sending request data to the server.
  ///
  /// Applies to all requests unless overridden per-request via
  /// [RestApiClientRequestOptions.sendTimeout].
  /// When null, no timeout is applied.
  final Duration? sendTimeout;

  /// Default timeout for receiving response data from the server.
  ///
  /// Applies to all requests unless overridden per-request via
  /// [RestApiClientRequestOptions.receiveTimeout].
  /// When null, no timeout is applied.
  final Duration? receiveTimeout;

  /// Constructor for creating an instance of RestApiClientOptions.
  ///
  /// The [baseUrl] parameter must be provided to specify the
  /// API endpoint, while the other options have default values.
  RestApiClientOptions({
    this.baseUrl = '',
    this.overrideBadCertificate = true,
    this.cacheEnabled = false,
    this.connectTimeout,
    this.sendTimeout,
    this.receiveTimeout,
  });
}
