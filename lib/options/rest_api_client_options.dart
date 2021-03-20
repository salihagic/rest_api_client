import 'package:dio/dio.dart';

class RestApiClientOptions {
  final String baseUrl;
  final bool logNetworkTraffic;
  final String refreshTokenEndpoint;
  final String refreshTokenParameterName;
  final String Function(Response<dynamic> response)? resolveJwt;
  final String Function(Response<dynamic> response)? resolveRefreshToken;
  final Map<dynamic, dynamic> Function(DioError error)? resolveValidationErrorsMap;

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
