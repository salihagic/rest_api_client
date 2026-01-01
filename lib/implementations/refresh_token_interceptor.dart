import 'dart:io';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:rest_api_client/rest_api_client.dart';

/// A Dio interceptor that handles refreshing of JWT tokens.
/// This interceptor can automatically refresh the token before it expires,
/// or handle token refresh upon receiving an unauthorized response.
class RefreshTokenInterceptor extends QueuedInterceptorsWrapper {
  final AuthHandler authHandler;
  final ExceptionHandler exceptionHandler;
  final ExceptionOptions exceptionOptions;
  final AuthOptions authOptions;

  /// Constructor for RefreshTokenInterceptor
  RefreshTokenInterceptor({
    required this.authHandler,
    required this.exceptionHandler,
    required this.exceptionOptions,
    required this.authOptions,
  });

  /// Determines if the interceptor should preemptively refresh the token
  /// before it expires.
  bool get isPreemptivelyRefreshBeforeExpiry =>
      authHandler.usesAuth &&
      authOptions.refreshTokenExecutionType ==
          RefreshTokenStrategy.preemptivelyRefreshBeforeExpiry;

  /// Determines if the interceptor should retry the request
  /// after refreshing the token.
  bool get isResponseAndRetry =>
      authHandler.usesAuth &&
      authOptions.refreshTokenExecutionType ==
          RefreshTokenStrategy.responseAndRetry;

  /// Checks if auth is required for the given request.
  /// Per-request override takes precedence over global setting.
  bool _isAuthRequired(RequestOptions options) {
    final perRequestOverride = options.extra['requiresAuth'];
    if (perRequestOverride is bool) {
      return perRequestOverride;
    }
    return authOptions.requiresAuth;
  }

  /// Called before a request is sent.
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

  /// Called when the response is about to be resolved.
  @override
  void onResponse(Response response, handler) {
    return handler.next(response);
  }

  /// Called when an exception occurs during the request.
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
