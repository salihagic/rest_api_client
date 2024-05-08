import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:rest_api_client/rest_api_client.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //This must be called once per application lifetime
  await RestApiClient.initFlutter();

  RestApiClient restApiClient = RestApiClientImpl(
    options: RestApiClientOptions(
      //Defines your base API url eg. https://mybestrestapi.com
      baseUrl: 'https://gorest.co.in/public/v2/',

      //Enable caching of response data
      cacheEnabled: true,
    ),
    authOptions: AuthOptions(
      //Define refresh token endpoint for RestApiClient
      //instance to use the first time response status code is 401
      refreshTokenEndpoint: '/api/auth/refresh-token',

      //Define the name of your api parameter name
      //on RefreshToken endpoint eg. 'refreshToken' or 'value' ...
      refreshTokenParameterName: 'token',

      refreshTokenBodyBuilder: (jwt, refreshToken) => {
        'accessToken': jwt,
        'refreshToken': refreshToken,
      },

      refreshTokenHeadersBuilder: (jwt, _) => {
        RestApiClientKeys.authorization: 'Bearer $jwt',
      },

      //This method is called on successfull call to refreshTokenEndpoint
      //Provides a way to get a jwt from response, much like
      //resolveValidationErrorsMap callback
      resolveJwt: (response) => response.data['accessToken'],

      //Much like resolveJwt, this method is used to resolve
      //refresh token from response
      resolveRefreshToken: (response) => response.data['refreshToken'],
    ),
    loggingOptions: LoggingOptions(
      //Toggle logging of your requests and responses
      //to the console while debugging
      logNetworkTraffic: true,
    ),
    exceptionOptions: ExceptionOptions(
      resolveValidationErrorsMap: (response) {
        if (response != null && response.data != null && response.data['code'] != null) {
          return {
            'ERROR': [response.data['code']],
          };
        }

        return {};
      },
    ),
    cacheOptions: CacheOptions(
      useAuthorization: true,
      cacheLifetimeDuration: const Duration(days: 10),
      resetOnRestart: false,
    ),
    interceptors: [
      InterceptorsWrapper(
        onRequest: (options, handler) {
          log('Logging before request');

          return handler.next(options);
        },
        onResponse: (response, handler) {
          log('Logging on response');

          return handler.next(response);
        },
        onError: (DioException e, handler) {
          log('Logging on error');

          return handler.next(e);
        },
      ),
    ],
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
  restApiClient.authorize(jwt: jwt, refreshToken: refreshToken);

  //Create authorized requests safely
  restApiClient.get('/Products');

  //Ignore server errors that might happen in the next request
  restApiClient.exceptionHandler.exceptionOptions.showInternalServerErrors = false;

  try {
    restApiClient.get(
      '/Products',
      queryParameters: {'name': 'darts'},
    );
  } catch (e) {
    print(e);
  }

  //Ignore all exceptions that might happen in the next request
  restApiClient.exceptionHandler.exceptionOptions.disable();

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
