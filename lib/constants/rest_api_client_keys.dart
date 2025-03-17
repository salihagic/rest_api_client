/// A class that contains constant keys used by the RestApiClient.
///
/// This class centralizes key strings used in headers, caching, and storage
/// for the REST API client implementation, helping to avoid magic strings
/// scattered throughout the codebase.
class RestApiClientKeys {
  /// The HTTP header key for authorization tokens.
  static const String authorization = 'Authorization';

  /// The HTTP header key used to specify the language preference of the client.
  static const String acceptLanguage = 'Accept-Language';

  /// The HTTP header key used to specify the media type of the resource,
  /// typically 'application/json' or 'application/xml'.
  static const String contentType = 'Content-Type';

  /// Key used to store the JSON Web Token (JWT) required for authorization.
  static const String jwt = '__REST_API_CLIENT:JWT';

  /// Key used to store the refresh token which can be used to obtain a new JWT.
  static const String refreshToken = '__REST_API_CLIENT:REFRESH_TOKEN';

  /// Key used for caching data in the repository for the REST API client.
  static const String cachedStorageKey =
      '___REST_API_CLIENT:CACHED_STORAGE_REPOSITORY';

  /// Key used for the primary storage repository for the REST API client.
  static const String storageKey = '___REST_API_CLIENT:STORAGE_REPOSITORY';

  /// Prefix used in logging for the cached storage operations of the REST API client.
  static const String cachedStorageLogPrefix = 'Rest api client cache storage';

  /// Prefix used in logging for the primary storage operations of the REST API client.
  static const String storageLogPrefix = 'Rest api client storage';
}
