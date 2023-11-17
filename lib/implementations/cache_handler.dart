import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:rest_api_client/constants/rest_api_client_keys.dart';
import 'package:rest_api_client/options/cache_options.dart';
import 'package:rest_api_client/options/logging_options.dart';
import 'package:storage_repository/storage_repository.dart';

class CacheHandler {
  final LoggingOptions loggingOptions;
  final CacheOptions cacheOptions;

  late StorageRepository _storage;

  CacheHandler({
    required this.loggingOptions,
    required this.cacheOptions,
  }) {
    _storage = StorageRepositoryImpl(
      key: RestApiClientKeys.cachedStorageKey,
      logPrefix: RestApiClientKeys.cachedStorageLogPrefix,
    );
  }

  Future init() async {
    await _storage.init();

    if (loggingOptions.logCacheStorage) {
      await _storage.log();
    }
  }

  Future<dynamic> get(RequestOptions options) async {
    final cacheKey = _generateCacheKey(options);

    return await _storage.get(cacheKey);
  }

  Future set(Response response) async {
    final cacheKey = _generateCacheKey(response.requestOptions);

    await _storage.set(cacheKey, response.data);
  }

  Future clear() async {
    await _storage.clear();
  }

  String _generateCacheKey(RequestOptions options) {
    final String authorization = cacheOptions.useAuthorization
        ? options.headers.containsKey(RestApiClientKeys.authorization)
            ? options.headers[RestApiClientKeys.authorization]
            : ''
        : '';
    final queryParametersSerialized = options.queryParameters.isNotEmpty
        ? json.encode(options.queryParameters)
        : '';
    final dataSerialized = (options.data != null && options.data.isNotEmpty)
        ? json.encode(options.data)
        : '';

    final combinedKey =
        _encode('$queryParametersSerialized$dataSerialized$authorization');

    final keyBase = cacheOptions.generateCacheKey?.call(options, combinedKey) ??
        combinedKey;

    final key = '${options.path} - ${_encode(keyBase)}';

    return key;
  }

  String _encode(String value) => md5.convert(utf8.encode(value)).toString();
}
