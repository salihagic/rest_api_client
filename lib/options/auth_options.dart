class AuthOptions {
  final bool useSecureStorage;
  final String refreshTokenEndpoint;
  final String refreshTokenParameterName;
  final RefreshTokenExecutionType refreshTokenExecutionType;
  final String Function(dynamic response)? resolveJwt;
  final String Function(dynamic response)? resolveRefreshToken;
  final dynamic Function(String jwt, String refreshToken)? refreshTokenBodyBuilder;
  final Map<String, dynamic>? Function(String jwt, String refreshToken)? refreshTokenHeadersBuilder;

  const AuthOptions({
    this.useSecureStorage = true,
    this.refreshTokenEndpoint = '',
    this.refreshTokenParameterName = '',
    this.refreshTokenExecutionType = RefreshTokenExecutionType.responseAndRetry,
    this.resolveJwt,
    this.resolveRefreshToken,
    this.refreshTokenBodyBuilder,
    this.refreshTokenHeadersBuilder,
  });
}

enum RefreshTokenExecutionType {
  responseAndRetry,
  preemptivelyRefreshBeforeExpiry,
}
