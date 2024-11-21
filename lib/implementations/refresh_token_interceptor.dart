import 'dart:io';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:rest_api_client/rest_api_client.dart';

class RefreshTokenInterceptor extends QueuedInterceptorsWrapper {
  final AuthHandler authHandler;
  final ExceptionHandler exceptionHandler;
  final ExceptionOptions exceptionOptions;
  final AuthOptions authOptions;

  RefreshTokenInterceptor({
    required this.authHandler,
    required this.exceptionHandler,
    required this.exceptionOptions,
    required this.authOptions,
  });

  bool get isPreemptivelyRefreshBeforeExpiry =>
      authHandler.usesAuth &&
      authOptions.refreshTokenExecutionType ==
          RefreshTokenStrategy.preemptivelyRefreshBeforeExpiry;
  bool get isResponseAndRetry =>
      authHandler.usesAuth &&
      authOptions.refreshTokenExecutionType ==
          RefreshTokenStrategy.responseAndRetry;

  @override
  void onRequest(RequestOptions options, handler) {
    options.extra.addAll({
      'showInternalServerErrors': exceptionOptions.showInternalServerErrors
    });
    options.extra
        .addAll({'showNetworkErrors': exceptionOptions.showNetworkErrors});
    options.extra.addAll(
        {'showValidationErrors': exceptionOptions.showValidationErrors});

    if (isPreemptivelyRefreshBeforeExpiry &&
        !authOptions.ignoreAuthForPaths.contains(options.path)) {
      try {
        final isExpired = JwtDecoder.isExpired(authHandler.jwt ?? '');

        if (isExpired) {
          authHandler.refreshTokenCallback(options, handler);
        } else {
          handler.next(options);
        }
      } catch (e) {
        print(e);
      }
    } else {
      handler.next(options);
    }
  }

  /// Called when the response is about to be resolved.
  @override
  void onResponse(Response response, handler) {
    exceptionOptions.reset();

    return handler.next(response);
  }

  /// Called when an exception was occurred during the request.
  @override
  void onError(DioException error, handler) async {
    if (isResponseAndRetry &&
        error.response?.statusCode == HttpStatus.unauthorized) {
      try {
        final response =
            await authHandler.refreshTokenCallback(error.requestOptions);

        if (response != null) {
          handler.resolve(response);
        } else {
          handler.next(error);
        }
      } catch (e) {
        print(e);
      }
    } else {
      handler.next(error);
    }
  }
}
