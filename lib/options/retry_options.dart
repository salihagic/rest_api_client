/// Configuration for automatic request retry with exponential backoff.
///
/// When enabled, failed requests are automatically retried with increasing
/// delays between attempts. This helps handle transient network issues and
/// server overload gracefully.
///
/// Example usage:
/// ```dart
/// RetryOptions(
///   enabled: true,
///   maxRetries: 3,
///   initialDelay: Duration(milliseconds: 500),
///   retryableStatusCodes: [500, 502, 503, 504],
/// )
/// ```
///
/// With default settings and [backoffMultiplier] of 2.0:
/// - 1st retry: 500ms delay
/// - 2nd retry: 1000ms delay
/// - 3rd retry: 2000ms delay
class RetryOptions {
  /// Whether automatic retry is enabled (default: false).
  ///
  /// Set to `true` to enable retry logic for failed requests.
  final bool enabled;

  /// Maximum number of retry attempts (default: 3).
  ///
  /// After this many failed attempts, the error is propagated to the caller.
  final int maxRetries;

  /// Delay before the first retry attempt (default: 500ms).
  ///
  /// Subsequent delays are calculated using [backoffMultiplier].
  final Duration initialDelay;

  /// Maximum delay between retry attempts (default: 30 seconds).
  ///
  /// This caps the exponential growth to prevent excessively long waits.
  final Duration maxDelay;

  /// Multiplier for exponential backoff (default: 2.0).
  ///
  /// Each retry delay is multiplied by this value:
  /// `delay = initialDelay * (backoffMultiplier ^ attemptNumber)`
  final double backoffMultiplier;

  /// HTTP status codes that trigger a retry.
  ///
  /// Default: `[408, 429, 500, 502, 503, 504]`
  /// - 408: Request Timeout
  /// - 429: Too Many Requests (rate limiting)
  /// - 500: Internal Server Error
  /// - 502: Bad Gateway
  /// - 503: Service Unavailable
  /// - 504: Gateway Timeout
  final List<int> retryableStatusCodes;

  /// Whether to retry on connection errors (default: true).
  ///
  /// When `true`, retries on connection timeouts, send timeouts,
  /// receive timeouts, and socket exceptions (no internet).
  final bool retryOnConnectionError;

  /// Creates retry options with the specified configuration.
  const RetryOptions({
    this.enabled = false,
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.retryableStatusCodes = const [408, 429, 500, 502, 503, 504],
    this.retryOnConnectionError = true,
  });

  /// Calculates the delay for a given retry attempt using exponential backoff.
  ///
  /// The [attempt] is 0-indexed (first retry is attempt 0).
  /// The returned duration is capped at [maxDelay].
  Duration getDelayForAttempt(int attempt) {
    final delayMs = initialDelay.inMilliseconds * _pow(backoffMultiplier, attempt);
    final cappedDelayMs = delayMs.clamp(0, maxDelay.inMilliseconds);
    return Duration(milliseconds: cappedDelayMs.toInt());
  }

  /// Calculates power without importing dart:math.
  double _pow(double base, int exponent) {
    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
