/// Configuration options for authentication handling.
class AuthOptions {
  /// Indicates whether to use secure storage for sensitive tokens.
  final bool useSecureStorage;

  /// The endpoint for refreshing tokens.
  final String refreshTokenEndpoint;

  /// Parameter name used for the refresh token in requests.
  final String refreshTokenParameterName;

  /// Strategy for handling refresh token requests.
  final RefreshTokenStrategy refreshTokenExecutionType;

  /// List of paths that do not require authentication.
  final List<String> ignoreAuthForPaths;

  /// Function to extract the JWT from the response.
  final String Function(dynamic response)? resolveJwt;

  /// Function to extract the refresh token from the response.
  final String Function(dynamic response)? resolveRefreshToken;

  /// Function to build the body for the refresh token request.
  final dynamic Function(String jwt, String refreshToken)?
      refreshTokenBodyBuilder;

  /// Function to build headers for the refresh token request.
  final Map<String, dynamic>? Function(String jwt, String refreshToken)?
      refreshTokenHeadersBuilder;

  /// Constructor to initialize the AuthOptions class with default values.
  const AuthOptions({
    this.useSecureStorage =
        true, // Default is true; tokens will be stored securely.
    this.refreshTokenEndpoint =
        '', // Default empty string; should be set to actual endpoint.
    this.refreshTokenParameterName =
        '', // Default empty; should be set to actual parameter name.
    this.refreshTokenExecutionType =
        RefreshTokenStrategy.responseAndRetry, // Default strategy.
    this.ignoreAuthForPaths = const [], // Default to an empty list.
    this.resolveJwt, // Optional function for JWT extraction.
    this.resolveRefreshToken, // Optional function for refresh token extraction.
    this.refreshTokenBodyBuilder, // Optional function to build request body for the refresh token request.
    this.refreshTokenHeadersBuilder, // Optional function to build request headers for the refresh token request.
  });
}

/// Enumeration for defining strategies for handling refresh tokens.
enum RefreshTokenStrategy {
  responseAndRetry, // Refresh token is processed as part of the response and retried if needed.
  preemptivelyRefreshBeforeExpiry, // Refresh token is fetched before the JWT expiry.
}
