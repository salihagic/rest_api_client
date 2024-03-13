import 'dart:io';

import 'package:rest_api_client/rest_api_client.dart';

class RefreshTokenInterceptor extends QueuedInterceptorsWrapper {
  final AuthHandler authHandler;
  final ExceptionHandler exceptionHandler;
  final ExceptionOptions exceptionOptions;

  RefreshTokenInterceptor({
    required this.authHandler,
    required this.exceptionHandler,
    required this.exceptionOptions,
  });

  void onRequest(RequestOptions options, handler) {
    options.extra.addAll({
      'showInternalServerErrors': exceptionOptions.showInternalServerErrors
    });
    options.extra
        .addAll({'showNetworkErrors': exceptionOptions.showNetworkErrors});
    options.extra.addAll(
        {'showValidationErrors': exceptionOptions.showValidationErrors});

    return handler.next(options);
  }

  /// Called when the response is about to be resolved.
  void onResponse(Response response, handler) {
    exceptionOptions.reset();

    return handler.next(response);
  }

  /// Called when an exception was occurred during the request.
  void onError(DioException error, handler) async {
    if (authHandler.usesAuth &&
        error.response?.statusCode == HttpStatus.unauthorized) {
      try {
        return handler.resolve(await authHandler.refreshTokenCallback(error));
      } catch (e) {
        print(e);
      }
    }

    await exceptionHandler.handle(error, error.requestOptions.extra);

    return handler.next(error);
  }
}
