/// Configuration options for JWT authentication and automatic token refresh.
///
/// Example usage:
/// ```dart
/// AuthOptions(
///   refreshTokenEndpoint: '/auth/refresh',
///   refreshTokenExecutionType: RefreshTokenStrategy.preemptivelyRefreshBeforeExpiry,
///   resolveJwt: (response) => response.data['access_token'],
///   resolveRefreshToken: (response) => response.data['refresh_token'],
/// )
/// ```
class AuthOptions {
  /// Whether to use secure (encrypted) storage for tokens.
  ///
  /// When `true` (default), tokens are stored using platform-specific secure storage
  /// (Keychain on iOS, EncryptedSharedPreferences on Android).
  /// When `false`, tokens are stored in regular SharedPreferences.
  final bool useSecureStorage;

  /// The API endpoint for refreshing tokens (e.g., `/auth/refresh`).
  ///
  /// This endpoint is called when the JWT expires and needs to be refreshed.
  final String refreshTokenEndpoint;

  /// The parameter name for the refresh token in the request body.
  ///
  /// Only used if [refreshTokenBodyBuilder] is not provided.
  /// The default request body will be: `{refreshTokenParameterName: refreshToken}`.
  final String refreshTokenParameterName;

  /// The strategy for handling token refresh.
  ///
  /// See [RefreshTokenStrategy] for available options.
  final RefreshTokenStrategy refreshTokenExecutionType;

  /// API paths that should skip authentication checks.
  ///
  /// Requests to these paths will not trigger token refresh even if the JWT is expired.
  /// Useful for public endpoints like login, registration, or health checks.
  final List<String> ignoreAuthForPaths;

  /// Whether authentication is required for requests by default.
  ///
  /// When `true` (default), requests will fail if token refresh fails.
  /// When `false`, requests will continue without authorization if token refresh fails,
  /// allowing the app to work in a "logged-out" state.
  ///
  /// Can be overridden per-request using [RestApiClientRequestOptions.requiresAuth].
  final bool requiresAuth;

  /// Callback to extract the new JWT from the refresh token response.
  ///
  /// Required for automatic token refresh to work.
  ///
  /// Example:
  /// ```dart
  /// resolveJwt: (response) => response.data['access_token']
  /// ```
  final String Function(dynamic response)? resolveJwt;

  /// Callback to extract the new refresh token from the refresh token response.
  ///
  /// Required for automatic token refresh to work.
  ///
  /// Example:
  /// ```dart
  /// resolveRefreshToken: (response) => response.data['refresh_token']
  /// ```
  final String Function(dynamic response)? resolveRefreshToken;

  /// Custom builder for the refresh token request body.
  ///
  /// If not provided, the default body is: `{refreshTokenParameterName: refreshToken}`.
  ///
  /// Example:
  /// ```dart
  /// refreshTokenBodyBuilder: (jwt, refreshToken) => {
  ///   'grant_type': 'refresh_token',
  ///   'refresh_token': refreshToken,
  /// }
  /// ```
  final dynamic Function(String jwt, String refreshToken)?
  refreshTokenBodyBuilder;

  /// Custom builder for the refresh token request headers.
  ///
  /// If not provided, the default header is: `{Authorization: 'Bearer $jwt'}`.
  ///
  /// Example:
  /// ```dart
  /// refreshTokenHeadersBuilder: (jwt, refreshToken) => {
  ///   'Authorization': 'Bearer $jwt',
  ///   'X-Refresh-Token': refreshToken,
  /// }
  /// ```
  final Map<String, dynamic>? Function(String jwt, String refreshToken)?
  refreshTokenHeadersBuilder;

  /// Creates authentication options with the specified configuration.
  const AuthOptions({
    this.useSecureStorage = true,
    this.refreshTokenEndpoint = '',
    this.refreshTokenParameterName = '',
    this.refreshTokenExecutionType = RefreshTokenStrategy.responseAndRetry,
    this.ignoreAuthForPaths = const [],
    this.requiresAuth = true,
    this.resolveJwt,
    this.resolveRefreshToken,
    this.refreshTokenBodyBuilder,
    this.refreshTokenHeadersBuilder,
  });
}

/// Strategy for handling JWT token refresh.
enum RefreshTokenStrategy {
  /// Refresh the token after receiving a 401 Unauthorized response, then retry the request.
  ///
  /// This is the default strategy. The original request is made, and if it returns 401,
  /// the token is refreshed and the request is automatically retried with the new token.
  responseAndRetry,

  /// Check token expiry before each request and refresh proactively if expired.
  ///
  /// This strategy prevents 401 errors by checking the JWT expiry time locally
  /// and refreshing before the request is made. Requires the JWT to contain
  /// a valid `exp` claim.
  preemptivelyRefreshBeforeExpiry,
}
