import 'package:dio/dio.dart';

/// Configuration options for caching responses in API calls.
class CacheOptions {
  /// A function to override the default cache key structure.
  ///
  /// This function can include the date and duration to enable cache lifetime control.
  final String Function(RequestOptions options, String key)? generateCacheKey;

  /// Indicates if the authorization header (e.g., JWT) will be part of the cache key.
  ///
  /// If your JWT refresh time is very short, setting this flag to true will invalidate all cache
  /// whenever the JWT is updated. Set it to false to exclude the JWT from the cache key structure.
  final bool useAuthorization;

  /// Specifies whether to use secure storage for cached responses.
  final bool useSecureStorage;

  /// The duration that defines how long the cache is valid.
  final Duration cacheLifetimeDuration;

  /// Determines whether the cache should be reset upon application restart.
  final bool resetOnRestart;

  /// Constructor to create a CacheOptions instance with specified settings.
  const CacheOptions({
    this.generateCacheKey,
    this.useAuthorization =
        true, // Default is true; JWT is included in cache key.
    this.useSecureStorage =
        false, // Default is false; responses are not stored securely by default.
    this.resetOnRestart =
        false, // Default is false; cache won't reset on restart.
    this.cacheLifetimeDuration =
        const Duration(days: 10), // Default cache lifetime is 10 days.
  });
}
