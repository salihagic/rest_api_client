// ignore_for_file: constant_identifier_names

class RestApiClientKeys {
  /// The HTTP header key for authorization tokens.
  static const String authorization = 'Authorization';

  /// The HTTP header key used to specify the language preference of the client.
  static const String acceptLanguage = 'Accept-Language';

  /// The HTTP header key used to specify the media type of the resource,
  /// typically 'application/json' or 'application/xml'.
  static const String contentType = 'Content-Type';

  /// Key used to store the JSON Web Token (JWT) required for authorization.
  static const String jwt = 'JWT';

  /// Key used to store the refresh token which can be used to obtain a new JWT.
  static const String refreshToken = 'REFRESH_TOKEN';

  /// Key used for the primary storage repository for the REST API client.
  static const String storageKey = 'REST_API_CLIENT_STORAGE';

  /// Key used for caching data in the repository for the REST API client.
  static const String cachedStorageKey = 'REST_API_CLIENT_CACHE_STORAGE';
}
