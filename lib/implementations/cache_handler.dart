import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:rest_api_client/rest_api_client.dart';
import 'package:storage_repository/storage_repository.dart';

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

  Future set(Response response) async {
    final cacheKey = _generateCacheKey(response.requestOptions);

    final cacheModel = CacheModel(
      expirationDateTime:
          DateTime.now().add(cacheOptions.cacheLifetimeDuration),
      value: response.data,
    );

    await _storage.set(cacheKey, cacheModel.toMap());
  }

  Future clear() async {
    await _storage.clear();
  }

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

  String _encode(String value) => md5.convert(utf8.encode(value)).toString();

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
