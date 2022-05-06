import 'package:flutter/material.dart';
import 'package:rest_api_client/implementations/default/rest_api_client_old.dart';
import 'package:rest_api_client/interfaces/i_rest_api_client_old.dart';
import 'package:rest_api_client/options/logging_options.dart';
import 'package:rest_api_client/options/rest_api_client_options_old.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //This must be called once per application lifetime
  await RestApiClientOld.initFlutter();

  IRestApiClientOld restApiClient = RestApiClientOld(
    restApiClientOptions: RestApiClientOptionsOld(
      //Defines your base API url eg. https://mybestrestapi.com
      baseUrl: 'https://mybestrestapi.com',

      ///Toggle logging of your requests and responses
      ///to the console while debugging
      keepRetryingOnNetworkError: true,

      //Define refresh token endpoint for RestApiClient
      //instance to use the first time response status code is 401
      refreshTokenEndpoint: '/Authentication/RefreshToken',

      //Define the name of your api parameter name
      //on RefreshToken endpoint eg. 'refreshToken' or 'value' ...
      refreshTokenParameterName: 'refreshToken',

      //This method is called on successfull call to refreshTokenEndpoint
      //Provides a way to get a jwt from response, much like
      //resolveValidationErrorsMap callback
      resolveJwt: (response) => response['jwt'],

      //Much like resolveJwt, this method is used to resolve
      //refresh token from response
      resolveRefreshToken: (response) => response['refreshToken'],

      //If your api returns validation errors different from
      //default format that is response.data['validationErrors']
      //you can override it by providing this callback
      resolveValidationErrorsMap: (response) => response['errors']['validation'],
    ),
    loggingOptions: LoggingOptions(
      //Toggle logging of your requests and responses
      //to the console while debugging
      logNetworkTraffic: true,
    ),
  );

  //init must be called, preferably right after the instantiation
  await restApiClient.init();

  //Use restApiClient from this point on

  //If you are using authentication in you app
  //probably it would look like this
  final response = await restApiClient.post(
    '/Authentication/Authenticate',
    data: {'username': 'john', 'password': 'Flutter_is_awesome1!'},
  );

  //Extract the values from response
  var jwt = response.data['jwt'];
  var refreshToken = response.data['refreshToken'];

  //Let's asume that somehow we got jwt and refresh token
  //Probably pinged our api Authentication endpoint to get these two values
  jwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwiZmx1dHRlciI6IkZsdXR0ZXIgaXMgYXdlc29tZSIsImNoYWxsZW5nZSI6IllvdSBtYWRlIGl0LCB5b3UgY3JhY2tlZCB0aGUgY29kZS4gWW91J3JlIGF3ZXNvbWUgdG9vLiIsImlhdCI6MTUxNjIzOTAyMn0.5QJz8hhxYsHxShS4hWKdHzcFH_IsQQZAnWSEcHJkspE';
  refreshToken = 'c91c03ea6c46a86cbc019be3d71d0a1a';

  //set the authorization
  restApiClient.addAuthorization(jwt: jwt, refreshToken: refreshToken);

  //Create authorized requests safely
  restApiClient.get('/Products');

  //Ignore server errors that might happen in the next request
  restApiClient.exceptionOptions.showInternalServerErrors = false;

  try {
    restApiClient.get(
      '/Products',
      queryParameters: {'name': 'darts'},
    );
  } catch (e) {
    print(e);
  }

  //Ignore all exceptions that might happen in the next request
  restApiClient.exceptionOptions.disable();

  restApiClient.post(
    '/Products/Reviews/234',
    data: {'grade': 5, 'comment': 'Throwing dart is not safe but upgrading to Dart 2.12.1 is. #nullsafety'},
  );

  restApiClient.put(
    '/Products/Reviews/234',
    data: {
      'grade': 5,
      'comment': 'On the other hand throwing dartz is fun',
    },
  );

  restApiClient.delete('/Products/Reviews/234');
}
