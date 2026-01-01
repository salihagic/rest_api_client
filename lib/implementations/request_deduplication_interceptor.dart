import 'dart:async';
import 'package:rest_api_client/rest_api_client.dart';

/// A Dio interceptor that deduplicates identical concurrent requests.
///
/// When multiple identical requests are made simultaneously (e.g., due to
/// rapid UI rebuilds or multiple widgets requesting the same data), only
/// the first request is actually sent to the server. Subsequent identical
/// requests wait for the first one to complete and receive the same response.
///
/// This optimization:
/// - Reduces unnecessary network traffic
/// - Prevents redundant server load
/// - Improves app performance by avoiding duplicate work
///
/// Requests are considered identical if they have the same:
/// - HTTP method
/// - Path
/// - Query parameters
/// - Authorization header
///
/// By default, only GET and HEAD requests are deduplicated since they are
/// safe and idempotent. POST, PUT, DELETE, and PATCH requests are not
/// deduplicated as they may have side effects.
///
/// Example:
/// ```dart
/// dio.interceptors.add(RequestDeduplicationInterceptor());
///
/// // These two concurrent calls will only result in one network request
/// final future1 = client.get('/users/123');
/// final future2 = client.get('/users/123');
///
/// // Both futures receive the same response
/// final results = await Future.wait([future1, future2]);
/// ```
class RequestDeduplicationInterceptor extends Interceptor {
  /// Map of in-flight requests, keyed by request signature.
  ///
  /// When a duplicate request arrives, it awaits the Completer from this map
  /// instead of making a new network request.
  final Map<String, Completer<Response>> _pendingRequests = {};

  /// Whether deduplication is enabled (default: true).
  final bool enabled;

  /// HTTP methods that should be deduplicated.
  ///
  /// Defaults to GET and HEAD as they are safe, idempotent methods.
  /// Avoid adding methods with side effects (POST, PUT, DELETE, PATCH).
  final List<String> deduplicateMethods;

  /// Creates a new [RequestDeduplicationInterceptor].
  RequestDeduplicationInterceptor({
    this.enabled = true,
    this.deduplicateMethods = const ['GET', 'HEAD'],
  });

  /// Intercepts outgoing requests and deduplicates them if applicable.
  ///
  /// For the first request with a given signature, creates a Completer and proceeds.
  /// For subsequent identical requests, waits for the first request's Completer.
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!enabled || !_shouldDeduplicate(options)) {
      return handler.next(options);
    }

    final key = _generateRequestKey(options);

    if (_pendingRequests.containsKey(key)) {
      _pendingRequests[key]!.future.then(
        (response) => handler.resolve(_cloneResponse(response, options)),
        onError: (error) => handler.reject(error as DioException),
      );
      return;
    }

    _pendingRequests[key] = Completer<Response>();
    options.extra['_deduplicationKey'] = key;
    handler.next(options);
  }

  /// Completes waiting requests when the original request succeeds.
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final key = response.requestOptions.extra['_deduplicationKey'] as String?;

    if (key != null && _pendingRequests.containsKey(key)) {
      _pendingRequests[key]!.complete(response);
      _pendingRequests.remove(key);
    }

    handler.next(response);
  }

  /// Propagates errors to waiting requests when the original request fails.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final key = err.requestOptions.extra['_deduplicationKey'] as String?;

    if (key != null && _pendingRequests.containsKey(key)) {
      _pendingRequests[key]!.completeError(err);
      _pendingRequests.remove(key);
    }

    handler.next(err);
  }

  /// Checks if the request method is in the [deduplicateMethods] list.
  bool _shouldDeduplicate(RequestOptions options) {
    final method = options.method.toUpperCase();
    return deduplicateMethods.contains(method);
  }

  /// Generates a unique signature for request deduplication.
  ///
  /// The signature includes method, path, sorted query parameters, and
  /// authorization header to ensure requests with different auth contexts
  /// are not incorrectly deduplicated.
  String _generateRequestKey(RequestOptions options) {
    final method = options.method;
    final path = options.path;
    final queryParams =
        options.queryParameters.entries
            .map((e) => '${e.key}=${e.value}')
            .toList()
          ..sort();
    final authHeader = options.headers[RestApiClientKeys.authorization] ?? '';

    return '$method:$path:${queryParams.join('&')}:$authHeader';
  }

  /// Creates a copy of the response with updated request options.
  ///
  /// Each waiting request receives a response with its own RequestOptions
  /// to maintain proper context.
  Response _cloneResponse(Response original, RequestOptions newOptions) {
    return Response(
      requestOptions: newOptions,
      data: original.data,
      statusCode: original.statusCode,
      statusMessage: original.statusMessage,
      headers: original.headers,
      extra: original.extra,
      isRedirect: original.isRedirect,
      redirects: original.redirects,
    );
  }
}
