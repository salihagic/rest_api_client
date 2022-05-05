import 'dart:async';
import 'package:rest_api_client/rest_api_client.dart';

///Abstract class to be used as an interface
///for implementing RestApiClient classes
///Extends DioMixin so the underlying features
///of the dio package are also awailable
abstract class IRestApiClientOld extends DioMixin {
  ///Defines options for handling exceptions per request
  ///Any direct changes to this instances properties
  ///are discarded after the response is handled
  late ExceptionOptions exceptionOptions;

  ///Provides a way for the user to listen to any
  ///RestApiClient exceptions that might happen during
  ///the execution of requests
  // ignore: close_sinks
  late StreamController<BaseException> exceptions;

  ///Get jwt from storage
  Future<String> get jwt;

  ///Get refresh token from storage
  Future<String> get refreshToken;

  ///Method that initializes RestApiClient instance
  Future<IRestApiClientOld> init();

  ///Best to call this method to set free allocated
  ///resources that the RestApiClient instacte might
  ///have allocated
  Future dispose();

  ///Method that sets appropriate Accept language header
  void setAcceptLanguageHeader(String languageCode);

  ///Method that adds Authorization header
  ///and initializes mechanism for managing
  ///refresh token logic
  Future<bool> addAuthorization({required String jwt, required String refreshToken});

  ///Removes authorization header along with jwt
  ///and refreshToken from the secure storage
  Future<bool> removeAuthorization();

  ///Provides information if the current instance
  ///of RestApiClient contains Authorization header
  Future<bool> isAuthorized();

  ///Clears secure storage
  Future clearSecureStorage();

  ///Clears cache storage
  Future clearCacheStorage();

  /// Handy method to make http GET request and cache reponse data
  @Deprecated('Use simple get method and set RestApiClientOptions cacheResponse flag to true to enable caching')
  Future<Response<T>> getAndCache<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http POST request and cache response data
  @Deprecated('Use simple post method and set RestApiClientOptions cacheResponse flag to true to enable caching')
  Future<Response<T>> postAndCache<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  ///Gets locally saved last response from the path
  Future<Response<T>> getCached<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });

  ///Gets locally saved last response from the path
  Future<Response<T>> postCached<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });
}
