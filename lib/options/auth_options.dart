class AuthOptions {
  final String refreshTokenEndpoint;
  final String refreshTokenParameterName;
  final String Function(dynamic response)? resolveJwt;
  final String Function(dynamic response)? resolveRefreshToken;

  const AuthOptions({
    this.refreshTokenEndpoint = '',
    this.refreshTokenParameterName = '',
    this.resolveJwt,
    this.resolveRefreshToken,
  });
}
