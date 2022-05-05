import 'package:rest_api_client/options/auth_options.dart';
import 'package:rest_api_client/options/logging_options.dart';

class RestApiClientOptions {
  final String baseUrl;
  final bool overrideBadCertificate;
  final bool cacheEnabled;
  final LoggingOptions loggingOptions;

  final AuthOptions authOptions;

  RestApiClientOptions({
    this.baseUrl = '',
    this.overrideBadCertificate = true,
    this.cacheEnabled = false,
    this.loggingOptions = const LoggingOptions(),
    this.authOptions = const AuthOptions(),
  });
}
