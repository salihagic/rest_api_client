import 'dart:io';
import 'package:flutter/foundation.dart';
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

  /// Called before a request is sent.
  @override
  void onRequest(RequestOptions options, handler) {
    if (isPreemptivelyRefreshBeforeExpiry &&
        !authOptions.ignoreAuthForPaths.contains(options.path)) {
      try {
        final bearer = options.headers[RestApiClientKeys.jwt];
        final jwt = bearer != null
            ? (bearer as String).replaceAll('Bearer ', '')
            : '';

        final isExpired = JwtDecoder.isExpired(jwt);

        if (isExpired) {
          authHandler.refreshTokenCallback(options, handler);
        } else {
          handler.next(options);
        }
      } catch (e) {
        debugPrint(e.toString());
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
        debugPrint(e.toString());
      }
    } else {
      handler.next(error);
    }
  }
}
