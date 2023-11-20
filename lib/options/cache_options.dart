import 'package:dio/dio.dart';

class CacheOptions {
  // By providing this function you can override default cache key structure,
  // you can include Date + Duration to enable cache lifetime control
  final String Function(RequestOptions options, String key)? generateCacheKey;

  // Defines if the authorization header (eg. JWT) will be a part of the
  // cache key, if your JWT refresh time is very short, when JWT is updated
  // all cache is invalidated if this flag is set to true.
  // Set it to false to ignore JWT from cache key structure.
  final bool useAuthorization;

  final Duration cacheLifetimeDuration;

  const CacheOptions({
    this.generateCacheKey,
    this.useAuthorization = true,
    this.cacheLifetimeDuration = const Duration(days: 10),
  });
}
