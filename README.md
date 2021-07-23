# Rest api client
Abstraction for communicating with REST API in flutter projects. Incorporates exception handling and jwt with refresh token authorization.
You can also find this package on pub as [rest_api_client](https://pub.dev/packages/rest_api_client)

## Usage
```
  IRestApiClient restApiClient = RestApiClient(
    restApiClientOptions: RestApiClientOptions(
      //Defines your base API url eg. https://mybestrestapi.com
      baseUrl: 'https://mybestrestapi.com',

      //Toggle logging of your requests and responses
      //to the console while debugging
      logNetworkTraffic: true,

      //Sets the flag deciding if the instance of restApiClient should retry to
      //submit the request after the device reconnects to the network
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

      ///Set the [useCache] flag if you want save every response from GET requests
      ///and afterwards be able to use [getCached] method to retrieve local item quickly
      useCache: true,
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
```

Ignore server errors that might happen in the next request
```
  restApiClient.exceptionOptions.showInternalServerErrors = false;

  try {
    restApiClient.get(
      '/Products',
      queryParameters: {
        'name': 'darts'
      },
    );
  } catch (e) {
    print(e);
  }
```

Ignore all exceptions that might happen in the next request
```
  restApiClient.exceptionOptions.disable();

  //Possible errors are ignored for this request
  restApiClient.post(
    '/Products/Reviews/234',
    data: {
      'grade': 5,
      'comment': 'Throwing darts is not safe but upgrading to dart ^2.12.1 is. #nullsafety'
    },
  );

  //Possible errors are handled for this request
  restApiClient.put(
    '/Products/Reviews/234',
    data: {
      'grade': 5,
      'comment': 'On the other hand throwing dartz is fun',
    },
  );

  restApiClient.delete('/Products/Reviews/234');
```