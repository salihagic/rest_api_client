# Rest API Client

A production-ready HTTP client for Flutter applications that simplifies REST API communication with built-in support for JWT authentication, automatic token refresh, response caching, retry logic, and comprehensive error handling.

[![pub package](https://img.shields.io/pub/v/rest_api_client.svg)](https://pub.dev/packages/rest_api_client)

## Features

- **JWT Authentication** - Automatic token management with secure storage (Keychain/EncryptedSharedPreferences)
- **Token Refresh** - Two strategies: response-and-retry or preemptive refresh before expiry
- **Response Caching** - Intelligent caching with configurable expiration
- **Retry Logic** - Exponential backoff for failed requests
- **Request Deduplication** - Prevents duplicate concurrent requests
- **Exception Handling** - Typed exceptions with global error stream
- **Multi-Platform** - Works on iOS, Android, Web, and Desktop

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  rest_api_client: ^2.4.1
```

## Quick Start

```dart
import 'package:rest_api_client/rest_api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage (call once per app lifetime)
  await RestApiClient.initFlutter();

  // Create the client
  final client = RestApiClientImpl(
    options: RestApiClientOptions(
      baseUrl: 'https://api.example.com',
    ),
  );

  await client.init();

  // Make requests
  final result = await client.get('/users');

  if (result.hasData) {
    print(result.data);
  }
}
```

## Configuration

### Basic Options

```dart
RestApiClientImpl(
  options: RestApiClientOptions(
    baseUrl: 'https://api.example.com',
    cacheEnabled: true,  // Enable response caching
    overrideBadCertificate: true,  // For development only!
  ),
)
```

### Authentication

Configure JWT authentication with automatic token refresh:

```dart
RestApiClientImpl(
  options: RestApiClientOptions(baseUrl: 'https://api.example.com'),
  authOptions: AuthOptions(
    // Endpoint for refreshing tokens
    refreshTokenEndpoint: '/auth/refresh',

    // Token refresh strategy
    refreshTokenExecutionType: RefreshTokenStrategy.responseAndRetry,

    // Extract tokens from refresh response
    resolveJwt: (response) => response.data['accessToken'],
    resolveRefreshToken: (response) => response.data['refreshToken'],

    // Custom request body for token refresh
    refreshTokenBodyBuilder: (jwt, refreshToken) => {
      'accessToken': jwt,
      'refreshToken': refreshToken,
    },

    // Paths that don't require authentication
    ignoreAuthForPaths: ['/auth/login', '/auth/register'],

    // Use secure storage (Keychain/EncryptedSharedPreferences)
    useSecureStorage: true,
  ),
)
```

#### Token Refresh Strategies

| Strategy | Description |
|----------|-------------|
| `responseAndRetry` | Wait for 401 response, refresh token, retry request (default) |
| `preemptivelyRefreshBeforeExpiry` | Check JWT expiry before each request, refresh proactively |

### Caching

```dart
RestApiClientImpl(
  options: RestApiClientOptions(
    baseUrl: 'https://api.example.com',
    cacheEnabled: true,
  ),
  cacheOptions: CacheOptions(
    cacheLifetimeDuration: Duration(days: 7),
    useAuthorization: true,  // Include JWT in cache key
    resetOnRestart: false,   // Persist cache across app restarts
  ),
)
```

### Retry Logic

Enable automatic retry with exponential backoff:

```dart
RestApiClientImpl(
  options: RestApiClientOptions(baseUrl: 'https://api.example.com'),
  retryOptions: RetryOptions(
    enabled: true,
    maxRetries: 3,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 30),
    backoffMultiplier: 2.0,
    retryableStatusCodes: [408, 429, 500, 502, 503, 504],
    retryOnConnectionError: true,
  ),
)
```

### Logging

```dart
RestApiClientImpl(
  options: RestApiClientOptions(baseUrl: 'https://api.example.com'),
  loggingOptions: LoggingOptions(
    logNetworkTraffic: true,  // Log requests/responses to console
  ),
)
```

### Exception Handling

```dart
RestApiClientImpl(
  options: RestApiClientOptions(baseUrl: 'https://api.example.com'),
  exceptionOptions: ExceptionOptions(
    // Custom parser for validation errors from your API
    resolveValidationErrorsMap: (response) {
      if (response?.data?['errors'] != null) {
        return response.data['errors'];
      }
      return {};
    },
  ),
)
```

### Custom Interceptors

Add Dio interceptors for custom logic:

```dart
RestApiClientImpl(
  options: RestApiClientOptions(baseUrl: 'https://api.example.com'),
  interceptors: [
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add custom headers, logging, etc.
        options.headers['X-Custom-Header'] = 'value';
        handler.next(options);
      },
      onResponse: (response, handler) {
        // Process responses
        handler.next(response);
      },
      onError: (error, handler) {
        // Handle errors
        handler.next(error);
      },
    ),
  ],
)
```

## Making Requests

### Basic Requests

```dart
// GET request
final result = await client.get('/users');

// GET with query parameters
final result = await client.get('/users', queryParameters: {'page': 1, 'limit': 10});

// POST request
final result = await client.post('/users', data: {'name': 'John', 'email': 'john@example.com'});

// PUT request
final result = await client.put('/users/1', data: {'name': 'John Updated'});

// PATCH request
final result = await client.patch('/users/1', data: {'name': 'John Patched'});

// DELETE request
final result = await client.delete('/users/1');

// HEAD request
final result = await client.head('/users/1');
```

### With Type Conversion

Use `onSuccess` to parse responses into typed objects:

```dart
final result = await client.get<User>(
  '/users/1',
  onSuccess: (data) => User.fromJson(data),
);

if (result.hasData) {
  User user = result.data!;
  print(user.name);
}
```

### Per-Request Options

```dart
final result = await client.get(
  '/users',
  options: RestApiClientRequestOptions(
    headers: {'X-Custom': 'value'},
    contentType: 'application/json',
    requiresAuth: false,    // Skip authentication for this request
    silentException: true,  // Don't broadcast exceptions
  ),
);
```

## Caching Strategies

### Cache-First (Stale-While-Revalidate)

Returns cached data immediately, then fetches fresh data:

```dart
await for (final result in client.getStreamed('/users')) {
  if (result.hasData) {
    // First emission: cached data (if available)
    // Second emission: fresh network data
    updateUI(result.data);
  }
}
```

### Cache-Only

Get data from cache only (no network request):

```dart
final result = await client.getCached('/users');
if (result.hasData) {
  print('Cached data: ${result.data}');
}
```

### Cache-Or-Network

Try cache first, fall back to network:

```dart
final result = await client.getCachedOrNetwork('/users');
```

### Custom Cache Duration

```dart
final result = await client.get(
  '/users',
  cacheLifetimeDuration: Duration(hours: 1),
);
```

## Authentication

### Login Flow

```dart
// 1. Make login request
final loginResult = await client.post('/auth/login', data: {
  'email': 'user@example.com',
  'password': 'password123',
});

// 2. Authorize the client with received tokens
if (loginResult.hasData) {
  await client.authorize(
    jwt: loginResult.data['accessToken'],
    refreshToken: loginResult.data['refreshToken'],
  );
}

// 3. All subsequent requests will include the JWT
final userResult = await client.get('/users/me');
```

### Check Authorization Status

```dart
final isLoggedIn = await client.isAuthorized();
```

### Logout

```dart
await client.unAuthorize();
await client.clearStorage();  // Clear tokens and cached data
```

## Error Handling

### Result Object

All requests return a `Result<T>` object:

```dart
final result = await client.get('/users');

// Check for data
if (result.hasData) {
  print(result.data);
}

// Check for errors
if (result.isError) {
  print(result.exception);
}

// Check specific error types
if (result.isConnectionError) {
  print('No internet connection');
}

// Access HTTP status
print(result.statusCode);      // e.g., 200, 404, 500
print(result.statusMessage);   // e.g., "OK", "Not Found"
```

### Exception Types

| Exception | HTTP Status | Description |
|-----------|-------------|-------------|
| `ValidationException` | 400, 404, 422 | Input validation errors |
| `UnauthorizedException` | 401 | Authentication required |
| `ForbiddenException` | 403 | Access denied |
| `ServerErrorException` | 500, 502 | Server-side errors |
| `NetworkErrorException` | - | Connection issues |

### Global Exception Stream

Listen to all exceptions across the app:

```dart
client.exceptionHandler.exceptions.stream.listen((exception) {
  if (exception is UnauthorizedException) {
    // Redirect to login
    navigatorKey.currentState?.pushReplacementNamed('/login');
  } else if (exception is NetworkErrorException) {
    // Show offline banner
    showSnackBar('No internet connection');
  }
});
```

### Suppress Exceptions

```dart
// Suppress for a single request
final result = await client.get(
  '/users',
  options: RestApiClientRequestOptions(silentException: true),
);
```

## File Downloads

```dart
final result = await client.download(
  '/files/document.pdf',
  '/path/to/save/document.pdf',
  onReceiveProgress: (received, total) {
    final progress = (received / total * 100).toStringAsFixed(0);
    print('Download progress: $progress%');
  },
);
```

## Headers

```dart
// Set content type
client.setContentType('application/json');

// Set language
client.setAcceptLanguageHeader('en');

// Add custom header
client.addOrUpdateHeader(key: 'X-Api-Key', value: 'your-api-key');

// Access current headers
print(client.headers);
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:rest_api_client/rest_api_client.dart';

late RestApiClient apiClient;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RestApiClient.initFlutter();

  apiClient = RestApiClientImpl(
    options: RestApiClientOptions(
      baseUrl: 'https://api.example.com',
      cacheEnabled: true,
    ),
    authOptions: AuthOptions(
      refreshTokenEndpoint: '/auth/refresh',
      resolveJwt: (r) => r.data['accessToken'],
      resolveRefreshToken: (r) => r.data['refreshToken'],
    ),
    loggingOptions: LoggingOptions(logNetworkTraffic: true),
    retryOptions: RetryOptions(enabled: true, maxRetries: 3),
  );

  await apiClient.init();

  // Listen to auth errors globally
  apiClient.exceptionHandler.exceptions.stream.listen((e) {
    if (e is UnauthorizedException) {
      // Handle logout
    }
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: UserListScreen(),
    );
  }
}

class UserListScreen extends StatefulWidget {
  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final result = await apiClient.get('/users');

    setState(() {
      isLoading = false;
      if (result.hasData) {
        users = result.data;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Users')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(users[index]['name']));
        },
      ),
    );
  }
}
```

## API Reference

### RestApiClient Methods

| Method | Description |
|--------|-------------|
| `init()` | Initialize the client (required) |
| `get()` | GET request with optional caching |
| `getCached()` | Get from cache only |
| `getCachedOrNetwork()` | Cache-first, network fallback |
| `getStreamed()` | Stale-while-revalidate pattern |
| `post()` | POST request |
| `postCached()` | Get cached POST response |
| `postStreamed()` | Streamed POST with cache |
| `put()` | PUT request |
| `patch()` | PATCH request |
| `delete()` | DELETE request |
| `head()` | HEAD request |
| `download()` | Download file with progress |
| `authorize()` | Set JWT and refresh token |
| `unAuthorize()` | Clear authorization |
| `isAuthorized()` | Check auth status |
| `clearStorage()` | Clear tokens and cache |

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

Repository: [https://github.com/salihagic/rest_api_client](https://github.com/salihagic/rest_api_client)
