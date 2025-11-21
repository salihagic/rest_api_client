import 'dart:async';
import 'package:rest_api_client/rest_api_client.dart';
import 'package:storage_repository/storage_repository.dart';

/// An abstract class representing a REST API client.
abstract class RestApiClient {
  late AuthHandler authHandler; // Handler for authentication-related tasks
  late ExceptionHandler exceptionHandler; // Handler for managing exceptions
  late CacheHandler cacheHandler; // Handler for caching responses
  Map<String, String> get headers; // Gets the current request headers

  /// Initializes the client and its handlers.
  Future<RestApiClient> init();

  /// Sends a GET request to the specified [path].
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters, // Optional query parameters
    FutureOr<T> Function(dynamic data)? onSuccess, // Callback on success
    FutureOr<T> Function(dynamic data)? onError, // Callback on error
    RestApiClientRequestOptions? options, // Request options
    Duration?
    cacheLifetimeDuration, // Lifetime of cached data, defaults to CacheOptions.cacheLifetimeDuration
  });

  /// Gets a cached response from the specified [path].
  Future<Result<T>> getCached<T>(
    String path, {
    Map<String, dynamic>? queryParameters, // Optional query parameters
    FutureOr<T> Function(dynamic data)? onSuccess, // Callback on success
    FutureOr<T> Function(dynamic data)? onError, // Callback on error
  });

  /// Gets a cached response from the specified [path] or network response if cache miss or expired.
  Future<Result<T>> getCachedOrNetwork<T>(
    String path, {
    Map<String, dynamic>? queryParameters, // Optional query parameters
    FutureOr<T> Function(dynamic data)? onSuccess, // Callback on success
    FutureOr<T> Function(dynamic data)? onError, // Callback on error
    RestApiClientRequestOptions? options, // Request options
    Duration?
    cacheLifetimeDuration, // Lifetime of cached data, defaults to CacheOptions.cacheLifetimeDuration
  });

  /// Streams the result of a GET request to the specified [path].
  Stream<Result<T>> getStreamed<T>(
    String path, {
    Map<String, dynamic>? queryParameters, // Optional query parameters
    FutureOr<T> Function(dynamic data)? onSuccess, // Callback on success
    FutureOr<T> Function(dynamic data)? onError, // Callback on error
    RestApiClientRequestOptions? options, // Request options
    Duration?
    cacheLifetimeDuration, // Lifetime of cached data, defaults to CacheOptions.cacheLifetimeDuration
  });

  /// Sends a POST request to the specified [path].
  Future<Result<T>> post<T>(
    String path, {
    data, // The data to be sent in the body of the request
    Map<String, dynamic>? queryParameters, // Optional query parameters
    FutureOr<T> Function(dynamic data)? onSuccess, // Callback on success
    FutureOr<T> Function(dynamic data)? onError, // Callback on error
    RestApiClientRequestOptions? options, // Request options
    bool cacheEnabled = false, // Optional flag to enable caching
    Duration?
    cacheLifetimeDuration, // Lifetime of cached data, defaults to CacheOptions.cacheLifetimeDuration
  });

  /// Gets a cached response from a POST request to the specified [path].
  Future<Result<T>> postCached<T>(
    String path, {
    data, // The data to be sent in the body of the request
    Map<String, dynamic>? queryParameters, // Optional query parameters
    FutureOr<T> Function(dynamic data)? onSuccess, // Callback on success
    FutureOr<T> Function(dynamic data)? onError, // Callback on error
  });

  /// Streams the result of a POST request to the specified [path].
  Stream<Result<T>> postStreamed<T>(
    String path, {
    data, // The data to be sent in the body of the request
    Map<String, dynamic>? queryParameters, // Optional query parameters
    FutureOr<T> Function(dynamic data)? onSuccess, // Callback on success
    FutureOr<T> Function(dynamic data)? onError, // Callback on error
    RestApiClientRequestOptions? options, // Request options
    Duration?
    cacheLifetimeDuration, // Lifetime of cached data, defaults to CacheOptions.cacheLifetimeDuration
  });

  /// Sends a PUT request to the specified [path].
  Future<Result<T>> put<T>(
    String path, {
    data, // The data to be updated
    Map<String, dynamic>? queryParameters, // Optional query parameters
    FutureOr<T> Function(dynamic data)? onSuccess, // Callback on success
    FutureOr<T> Function(dynamic data)? onError, // Callback on error
    RestApiClientRequestOptions? options, // Request options
  });

  /// Sends a HEAD request to the specified [path].
  Future<Result<T>> head<T>(
    String path, {
    data, // Optional data to send with the request
    Map<String, dynamic>? queryParameters, // Optional query parameters
    FutureOr<T> Function(dynamic data)? onSuccess, // Callback on success
    FutureOr<T> Function(dynamic data)? onError, // Callback on error
    RestApiClientRequestOptions? options, // Request options
  });

  /// Sends a DELETE request to the specified [path].
  Future<Result<T>> delete<T>(
    String path, {
    data, // Optional data to send with the request
    Map<String, dynamic>? queryParameters, // Optional query parameters
    FutureOr<T> Function(dynamic data)? onSuccess, // Callback on success
    FutureOr<T> Function(dynamic data)? onError, // Callback on error
    RestApiClientRequestOptions? options, // Request options
  });

  /// Sends a PATCH request to the specified [path].
  Future<Result<T>> patch<T>(
    String path, {
    data, // The data to be updated
    Map<String, dynamic>? queryParameters, // Optional query parameters
    FutureOr<T> Function(dynamic data)? onSuccess, // Callback on success
    FutureOr<T> Function(dynamic data)? onError, // Callback on error
    RestApiClientRequestOptions? options, // Request options
  });

  /// Downloads a file from the specified [urlPath] to [savePath].
  Future<Result<T>> download<T>(
    String urlPath,
    savePath, {
    data, // Optional data to send with the request
    Map<String, dynamic>? queryParameters, // Optional query parameters
    RestApiClientRequestOptions? options, // Request options
    ProgressCallback? onReceiveProgress, // Callback for download progress
    CancelToken? cancelToken, // Token to cancel the request
    bool deleteOnError = true, // Deletes the file if an error occurs
    String lengthHeader =
        Headers.contentLengthHeader, // Length header for the request
    FutureOr<T> Function(dynamic data)? onSuccess, // Callback on success
    FutureOr<T> Function(dynamic data)? onError, // Callback on error
  });

  /// Sets the content type for the requests.
  void setContentType(String contentType);

  /// Sets the Accept-Language header for the requests.
  void setAcceptLanguageHeader(String languageCode);

  /// Adds or updates a header in the request.
  void addOrUpdateHeader({required String key, required String value});

  /// Authorizes the client with a JWT and refresh token.
  Future<bool> authorize({required String jwt, required String refreshToken});

  /// Unauthorizes the client, typically for logging out.
  Future<bool> unAuthorize();

  /// Checks if the client is authorized.
  Future<bool> isAuthorized();

  /// Clears stored credentials and cached data.
  Future clearStorage();

  /// Initializes the Flutter storage repository.
  static Future<void> initFlutter([
    bool skipWidgetsFlutterBindingInitialization = false,
  ]) async => await StorageRepository.initFlutter(
    skipWidgetsFlutterBindingInitialization,
  );
}
