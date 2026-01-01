import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:rest_api_client/rest_api_client.dart';

/// A Dio interceptor that automatically retries failed requests with exponential backoff.
///
/// This interceptor handles transient failures by retrying requests that fail due to:
/// - Connection timeouts, send timeouts, receive timeouts
/// - Network errors (no internet connection)
/// - Configurable HTTP status codes (default: 408, 429, 500, 502, 503, 504)
///
/// The delay between retries increases exponentially to avoid overwhelming
/// servers that may be experiencing high load.
///
/// Example:
/// ```dart
/// dio.interceptors.add(
///   RetryInterceptor(
///     dio: dio,
///     retryOptions: RetryOptions(
///       enabled: true,
///       maxRetries: 3,
///       initialDelay: Duration(milliseconds: 500),
///     ),
///   ),
/// );
/// ```
class RetryInterceptor extends Interceptor {
  /// The Dio instance used to retry requests.
  final Dio dio;

  /// Configuration options for retry behavior.
  final RetryOptions retryOptions;

  /// Creates a new [RetryInterceptor].
  RetryInterceptor({required this.dio, required this.retryOptions});

  /// Handles errors and retries the request if appropriate.
  ///
  /// The request is retried if:
  /// - Retry is enabled in [retryOptions]
  /// - The maximum retry count hasn't been reached
  /// - The error is retryable (connection error or matching status code)
  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    if (!retryOptions.enabled) {
      return handler.next(error);
    }

    final attempt = _getAttemptCount(error.requestOptions);

    if (attempt >= retryOptions.maxRetries) {
      return handler.next(error);
    }

    if (!_shouldRetry(error)) {
      return handler.next(error);
    }

    final delay = retryOptions.getDelayForAttempt(attempt);

    debugPrint(
      'RetryInterceptor: Retry attempt ${attempt + 1}/${retryOptions.maxRetries} '
      'after ${delay.inMilliseconds}ms for ${error.requestOptions.path}',
    );

    await Future.delayed(delay);

    try {
      final newOptions = error.requestOptions;
      _setAttemptCount(newOptions, attempt + 1);

      final response = await dio.request(
        newOptions.path,
        data: newOptions.data,
        queryParameters: newOptions.queryParameters,
        cancelToken: newOptions.cancelToken,
        onReceiveProgress: newOptions.onReceiveProgress,
        onSendProgress: newOptions.onSendProgress,
        options: Options(
          method: newOptions.method,
          headers: newOptions.headers,
          extra: newOptions.extra,
          responseType: newOptions.responseType,
          contentType: newOptions.contentType,
          validateStatus: newOptions.validateStatus,
          receiveDataWhenStatusError: newOptions.receiveDataWhenStatusError,
          followRedirects: newOptions.followRedirects,
          maxRedirects: newOptions.maxRedirects,
          requestEncoder: newOptions.requestEncoder,
          responseDecoder: newOptions.responseDecoder,
          listFormat: newOptions.listFormat,
          sendTimeout: newOptions.sendTimeout,
          receiveTimeout: newOptions.receiveTimeout,
        ),
      );

      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Determines if the error should trigger a retry.
  ///
  /// Returns `true` if the error is a connection/timeout error (when enabled)
  /// or if the HTTP status code is in [RetryOptions.retryableStatusCodes].
  bool _shouldRetry(DioException error) {
    if (retryOptions.retryOnConnectionError) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return true;
      }

      if (error.error is SocketException) {
        return true;
      }
    }

    final statusCode = error.response?.statusCode;
    if (statusCode != null &&
        retryOptions.retryableStatusCodes.contains(statusCode)) {
      return true;
    }

    return false;
  }

  /// Gets the current retry attempt count from request options.
  int _getAttemptCount(RequestOptions options) {
    return options.extra['_retryAttempt'] as int? ?? 0;
  }

  /// Increments the retry attempt count in request options.
  void _setAttemptCount(RequestOptions options, int attempt) {
    options.extra['_retryAttempt'] = attempt;
  }
}
