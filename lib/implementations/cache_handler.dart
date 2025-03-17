import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:rest_api_client/rest_api_client.dart';
import 'package:storage_repository/storage_repository.dart';

/// A class for managing cached data to optimize API request handling.
class CacheHandler {
  final LoggingOptions loggingOptions;
  final CacheOptions cacheOptions;

  late StorageRepository _storage;

  CacheHandler({
    required this.loggingOptions,
    required this.cacheOptions,
  }) {
    _storage = cacheOptions.useSecureStorage
        ? SecureStorageRepositoryImpl(
            key: RestApiClientKeys.cachedStorageKey,
            logPrefix: RestApiClientKeys.cachedStorageLogPrefix,
          )
        : StorageRepositoryImpl(
            key: RestApiClientKeys.cachedStorageKey,
            logPrefix: RestApiClientKeys.cachedStorageLogPrefix,
          );
  }

  /// Initializes the cache handler, clearing the storage if configured to do so.
  Future init() async {
    await _storage.init();

    if (cacheOptions.resetOnRestart) {
      await _storage.clear();
    } else {
      await _clearExpiredCacheData();
    }

    if (loggingOptions.logCacheStorage) {
      await _storage.log();
    }
  }

  /// Retrieves cached data for the given request options. Returns null if no valid cached data is found.
  Future<dynamic> get(RequestOptions options) async {
    final cacheKey = _generateCacheKey(options);

    final data = await _storage.get(cacheKey);

    if (data == null) {
      return null;
    }

    final cacheModel = CacheModel.fromMap(data);

    if (cacheModel.isExpired) {
      await _storage.delete(cacheKey);
      return null;
    }

    return cacheModel.value;
  }

  /// Caches the response data from a request.
  Future<void> set(Response response) async {
    final cacheKey = _generateCacheKey(response.requestOptions);

    final cacheModel = CacheModel(
      expirationDateTime:
          DateTime.now().add(cacheOptions.cacheLifetimeDuration),
      value: response.data,
    );

    await _storage.set(cacheKey, cacheModel.toMap());
  }

  /// Clears all cached data.
  Future<void> clear() async {
    await _storage.clear();
  }

  /// Generates a cache key based on the request options.
  String _generateCacheKey(RequestOptions options) {
    final queryParametersSerialized = options.queryParameters.isNotEmpty
        ? json.encode(options.queryParameters)
        : '';
    final dataSerialized = (options.data != null && options.data.isNotEmpty)
        ? json.encode(options.data)
        : '';
    final String authorization = cacheOptions.useAuthorization
        ? options.headers.containsKey(RestApiClientKeys.authorization)
            ? options.headers[RestApiClientKeys.authorization]
            : ''
        : '';

    final combinedKey =
        _encode('$queryParametersSerialized$dataSerialized$authorization');

    final keyBase = cacheOptions.generateCacheKey?.call(options, combinedKey) ??
        combinedKey;

    final key = '${options.path} - ${_encode(keyBase)}';

    return key;
  }

  /// Encodes a string using MD5 hashing.
  String _encode(String value) => md5.convert(utf8.encode(value)).toString();

  /// Removes expired cached data.
  Future<void> _clearExpiredCacheData() async {
    final data = await _storage.getAll();

    for (final entry in data.entries) {
      final cacheModel = CacheModel.fromMap(entry.value);

      if (cacheModel.isExpired) {
        await _storage.delete(entry.key);
      }
    }
  }
}
