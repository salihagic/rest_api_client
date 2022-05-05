///Use this class to provide configuration
///for your RestApiClient instance
class RestApiClientOptionsOld {
  ///Defines your base API url eg. https://mybestrestapi.com
  final String baseUrl;

  ///Sets the flag deciding if the instance of restApiClient should retry to
  ///submit the request after the device reconnects to the network
  final bool keepRetryingOnNetworkError;

  ///Sets the flag deciding if the response data will be cached
  final bool cacheResponse;

  ///Sets the flag deciding if the instance of restApiClient should ignore ssl
  ///certificate if it couldn't be decoded
  final bool overrideBadCertificate;

  ///Define refresh token endpoint for RestApiClient
  ///instance to use the first time response status code is 401
  final String refreshTokenEndpoint;

  ///Define the name of your api parameter name
  ///on RefreshToken endpoint eg. 'refreshToken' or 'value' ...
  final String refreshTokenParameterName;

  ///This method is called on successfull call to refreshTokenEndpoint
  ///Provides a way to get a jwt from response, much like
  ///resolveValidationErrorsMap callback
  final String Function(dynamic response)? resolveJwt;

  ///Much like resolveJwt, this method is used to resolve
  ///refresh token from response
  final String Function(dynamic response)? resolveRefreshToken;

  ///If your api returns validation errors different from
  ///default format that is response.data['validationErrors']
  ///you can override it by providing this callback
  final Map<String, List<String>> Function(dynamic response)? resolveValidationErrorsMap;

  RestApiClientOptionsOld({
    this.baseUrl = '',
    this.keepRetryingOnNetworkError = true,
    this.cacheResponse = false,
    this.overrideBadCertificate = true,
    this.refreshTokenEndpoint = '',
    this.refreshTokenParameterName = '',
    this.resolveJwt,
    this.resolveRefreshToken,
    this.resolveValidationErrorsMap,
  });
}
