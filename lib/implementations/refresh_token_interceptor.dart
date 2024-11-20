import 'dart:io';
import 'package:jwt_decoder/jwt_decoder.dart';
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

  @override
  void onRequest(RequestOptions options, handler) {
    options.extra.addAll({'showInternalServerErrors': exceptionOptions.showInternalServerErrors});
    options.extra.addAll({'showNetworkErrors': exceptionOptions.showNetworkErrors});
    options.extra.addAll({'showValidationErrors': exceptionOptions.showValidationErrors});

    if (authHandler.usesAuth) {
      try {
        final isExpired = JwtDecoder.isExpired(authHandler.jwt ?? '');

        print('JWT LOGS: IS EXPIRED JWT 7: ${isExpired}');

        return isExpired ? authHandler.refreshTokenCallback(options, handler) : handler.next(options);
      } catch (e) {
        print(e);
      }
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
    if (authHandler.usesAuth && error.response?.statusCode == HttpStatus.unauthorized) {
      try {
        final response = await authHandler.refreshTokenCallback(error.requestOptions);

        return response != null ? handler.resolve(response) : handler.next(error);
      } catch (e) {
        print(e);
      }
    }

    return handler.next(error);
  }
}
