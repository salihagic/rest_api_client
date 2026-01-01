import 'dart:io';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:rest_api_client/rest_api_client.dart';

/// A Dio interceptor that handles automatic JWT token refresh.
///
/// This interceptor supports two strategies for token refresh:
/// - **Preemptive refresh**: Checks token expiry before each request and refreshes
///   if expired, preventing 401 errors.
/// - **Response and retry**: Waits for a 401 response, then refreshes the token
///   and retries the failed request.
///
/// Uses [QueuedInterceptorsWrapper] to ensure token refresh requests are serialized,
/// preventing multiple concurrent refresh requests when several API calls fail
/// simultaneously.
///
/// Example usage:
/// ```dart
/// dio.interceptors.add(
///   RefreshTokenInterceptor(
///     authHandler: authHandler,
///     exceptionHandler: exceptionHandler,
///     exceptionOptions: exceptionOptions,
///     authOptions: AuthOptions(
///       refreshTokenExecutionType: RefreshTokenStrategy.preemptivelyRefreshBeforeExpiry,
///       refreshTokenEndpoint: '/auth/refresh',
///       resolveJwt: (response) => response.data['access_token'],
///       resolveRefreshToken: (response) => response.data['refresh_token'],
///     ),
///   ),
/// );
/// ```
class RefreshTokenInterceptor extends QueuedInterceptorsWrapper {
  /// Handler for authentication operations (token storage, refresh execution).
  final AuthHandler authHandler;

  /// Handler for processing exceptions that occur during token refresh.
  final ExceptionHandler exceptionHandler;

  /// Options for exception handling configuration.
  final ExceptionOptions exceptionOptions;

  /// Authentication configuration options.
  final AuthOptions authOptions;

  /// Creates a new [RefreshTokenInterceptor].
  ///
  /// All parameters are required to properly handle token refresh scenarios.
  RefreshTokenInterceptor({
    required this.authHandler,
    required this.exceptionHandler,
    required this.exceptionOptions,
    required this.authOptions,
  });

  /// Whether the preemptive refresh strategy is active.
  ///
  /// Returns `true` if:
  /// - The client currently has authorization headers set
  /// - The strategy is set to [RefreshTokenStrategy.preemptivelyRefreshBeforeExpiry]
  bool get isPreemptivelyRefreshBeforeExpiry =>
      authHandler.usesAuth &&
      authOptions.refreshTokenExecutionType ==
          RefreshTokenStrategy.preemptivelyRefreshBeforeExpiry;

  /// Whether the response-and-retry strategy is active.
  ///
  /// Returns `true` if:
  /// - The client currently has authorization headers set
  /// - The strategy is set to [RefreshTokenStrategy.responseAndRetry]
  bool get isResponseAndRetry =>
      authHandler.usesAuth &&
      authOptions.refreshTokenExecutionType ==
          RefreshTokenStrategy.responseAndRetry;

  /// Determines if authentication is required for the given request.
  ///
  /// Checks for a per-request override in `options.extra['requiresAuth']`.
  /// If not present, falls back to the global [AuthOptions.requiresAuth] setting.
  ///
  /// When auth is not required and token refresh fails, the request will
  /// continue without authorization rather than failing.
  bool _isAuthRequired(RequestOptions options) {
    final perRequestOverride = options.extra['requiresAuth'];
    if (perRequestOverride is bool) {
      return perRequestOverride;
    }
    return authOptions.requiresAuth;
  }

  /// Intercepts outgoing requests to check for token expiry (preemptive strategy).
  ///
  /// If [isPreemptivelyRefreshBeforeExpiry] is `true` and the JWT is expired:
  /// - Attempts to refresh the token before sending the request
  /// - If refresh succeeds, continues with the updated token
  /// - If refresh fails and auth is required, rejects the request
  /// - If refresh fails and auth is not required, removes the auth header and continues
  ///
  /// Paths listed in [AuthOptions.ignoreAuthForPaths] bypass token checking.
  @override
  void onRequest(RequestOptions options, handler) async {
    if (isPreemptivelyRefreshBeforeExpiry &&
        !authOptions.ignoreAuthForPaths.contains(options.path)) {
      try {
        final bearer = options.headers[RestApiClientKeys.authorization];
        final jwt = bearer != null
            ? (bearer as String).replaceAll('Bearer ', '')
            : '';

        if (jwt.isEmpty) {
          handler.next(options);
        } else {
          final isExpired = JwtDecoder.isExpired(jwt);

          if (isExpired) {
            await authHandler.refreshTokenCallback(options, handler);
          } else {
            handler.next(options);
          }
        }
      } catch (e) {
        if (_isAuthRequired(options)) {
          handler.reject(DioException(requestOptions: options, error: e));
        } else {
          // Auth not required - remove invalid token and continue without auth
          options.headers.remove(RestApiClientKeys.authorization);
          handler.next(options);
        }
      }
    } else {
      handler.next(options);
    }
  }

  /// Passes the response through without modification.
  ///
  /// This interceptor does not process successful responses; they are
  /// passed to the next interceptor in the chain.
  @override
  void onResponse(Response response, handler) {
    return handler.next(response);
  }

  /// Handles 401 Unauthorized errors (response-and-retry strategy).
  ///
  /// If [isResponseAndRetry] is `true` and the response status is 401:
  /// - Attempts to refresh the token
  /// - If refresh succeeds, retries the original request with the new token
  /// - If refresh fails and auth is required, rejects with the original error
  /// - If refresh fails and auth is not required, passes the error through
  ///
  /// Non-401 errors are passed through to the next error handler.
  @override
  void onError(DioException error, handler) async {
    if (isResponseAndRetry &&
        error.response?.statusCode == HttpStatus.unauthorized) {
      try {
        final response = await authHandler.refreshTokenCallback(
          error.requestOptions,
        );

        if (response != null) {
          handler.resolve(response);
        } else {
          handler.next(error);
        }
      } catch (e) {
        if (_isAuthRequired(error.requestOptions)) {
          handler.reject(error);
        } else {
          // Auth not required - continue with the original error
          handler.next(error);
        }
      }
    } else {
      handler.next(error);
    }
  }
}
