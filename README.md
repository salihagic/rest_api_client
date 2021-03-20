# Rest api client
Abstraction for communicating with REST API in flutter projects. Incorporates exception handling and jwt with refresh token authorization.
You can also find this package on pub as [rest_api_client](https://pub.dev/packages/rest_api_client)

## Usage
```
  IRestApiClient restApiClient = RestApiClient(
    exceptionOptions: RestApiClientExceptionOptions(
      showInternalServerErrors: true,
      showNetworkErrors: true,
      showValidationErrors: true,
    ),
    restApiClientOptions: RestApiClientOptions(
      //Base api url that will be prepended on every subsequent request
      baseUrl: 'https://mybestrestapi.com',
      //Default is true
      logNetworkTraffic: true,
      //If you api returns validation errors different from
      //default format that is response.data['validationErrors']
      //you can override it by providing this callback
      resolveValidationErrorsMap: (response) => response['errors']['validation'],
      refreshTokenEndpoint: '/Authentication/RefreshToken',
      refreshTokenParameterName: '<name_of_api_endpoint_parameter_for_refresh_token>',
      //This method is called on successfull call to refreshTokenEndpoint
      //Provides a way to get a jwt from response, much like
      //resolveValidationErrorsMap callback
      resolveJwt: (response) => response['jwt'],
      //Much like resolveJwt, this method is used to resolve
      //refresh token from response
      resolveRefreshToken: (response) => response['refreshToken'],
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
    data: {
      'username': 'john',
      'password': 'Flutter_is_awesome1!'
    },
  );

  final jwt = response.data['jwt'];
  final refreshToken = response.data['refreshToken'];
```

Let's asume that somehow we got jwt and refresh token,
you probably pinged your api Authentication endpoint to get these two values.
```
  final jwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwiZmx1dHRlciI6IkZsdXR0ZXIgaXMgYXdlc29tZSIsImNoYWxsZW5nZSI6IllvdSBtYWRlIGl0LCB5b3UgY3JhY2tlZCB0aGUgY29kZS4gWW91J3JlIGF3ZXNvbWUgdG9vLiIsImlhdCI6MTUxNjIzOTAyMn0.5QJz8hhxYsHxShS4hWKdHzcFH_IsQQZAnWSEcHJkspE';
  final refreshToken = 'c91c03ea6c46a86cbc019be3d71d0a1a';

  //set the authorization
  restApiClient.addAuthorization(jwt: jwt, refreshToken: refreshToken);

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

  restApiClient.post(
    '/Products/Reviews/234',
    data: {
      'grade': 5,
      'comment': 'Throwing darts is not safe but upgrading to dart ^2.12.1 is. #nullsafety'
    },
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