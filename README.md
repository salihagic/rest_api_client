# Rest api client
Abstraction for communicating with REST API in flutter projects. Incorporates exception handling and jwt with refresh token authorization.
You can also find this package on pub as [rest_api_client](https://pub.dev/packages/rest_api_client)

## Usage
```
  //This must be called once per application lifetime
  await RestApiClient.initFlutter();

  IRestApiClient restApiClient = RestApiClient(
    options: RestApiClientOptions(
      //Defines your base API url eg. https://mybestrestapi.com
      baseUrl: 'https://mybestrestapi.com',

      //Enable caching of response data
      cacheEnabled: true,
    ),
    authOptions: AuthOptions(
      //Define refresh token endpoint for RestApiClient
      //instance to use the first time response status code is 401
      refreshTokenEndpoint: '/auth/token-refresh',

      //Define the name of your api parameter name
      //on RefreshToken endpoint eg. 'refreshToken' or 'value' ...
      refreshTokenParameterName: 'token',

      //This method is called on successfull call to refreshTokenEndpoint
      //Provides a way to get a jwt from response, much like
      //resolveValidationErrorsMap callback
      resolveJwt: (response) => response.data['result']['accessToken']['token'],

      //Much like resolveJwt, this method is used to resolve
      //refresh token from response
      resolveRefreshToken: (response) => response.data['result']['refreshToken']['token'],
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
```

If you are using authentication in your app probably it would look something like this
```
  final response = await restApiClient.post(
    '/Authentication/Authenticate',
    data: {'username': 'john', 'password': 'Flutter_is_awesome1!'},
  );

  //Extract the values from response
  var jwt = response.data['jwt'];
  var refreshToken = response.data['refreshToken'];
```

Let's asume that somehow we got jwt and refresh token,
you probably pinged your api Authentication endpoint to get these two values.
```
  jwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwiZmx1dHRlciI6IkZsdXR0ZXIgaXMgYXdlc29tZSIsImNoYWxsZW5nZSI6IllvdSBtYWRlIGl0LCB5b3UgY3JhY2tlZCB0aGUgY29kZS4gWW91J3JlIGF3ZXNvbWUgdG9vLiIsImlhdCI6MTUxNjIzOTAyMn0.5QJz8hhxYsHxShS4hWKdHzcFH_IsQQZAnWSEcHJkspE';
  refreshToken = 'c91c03ea6c46a86cbc019be3d71d0a1a';

  //set the authorization
  restApiClient.authHandler.authorize(jwt: jwt, refreshToken: refreshToken);

  //Create authorized requests safely
  restApiClient.get('/Products');
```

Add parameters to your requests
```
  restApiClient.get(
    '/Products',
    queryParameters: {
      'name': 'darts'
    },
  );
```

Ignore server errors that might happen in the next request
```
  restApiClient.exceptionHandler.exceptionOptions.showInternalServerErrors = false;

  try {
    restApiClient.get(
      '/Products',
      queryParameters: {'name': 'darts'},
    );
  } catch (e) {
    print(e);
  }
```

Ignore all exceptions that might happen in the next request
```
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
  
```