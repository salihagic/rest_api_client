///Constant values used by RestApiClient
class RestApiClientKeys {
  static const String authorization = 'Authorization';
  static const String acceptLanguage = 'Accept-Language';
  static const String contentType = 'Content-Type';
  static const String multipartFormData = 'multipart/form-data';

  static const String jwt = '__REST_API_CLIENT:JWT';
  static const String refreshToken = '__REST_API_CLIENT:REFRESH_TOKEN';
  static const String cachedStorageKey =
      '___REST_API_CLIENT:CACHED_STORAGE_REPOSITORY';
  static const String storageKey = '___REST_API_CLIENT:STORAGE_REPOSITORY';

  static const String cachedStorageLogPrefix = 'Rest api client cache storage';
  static const String storageLogPrefix = 'Rest api client storage';
}
