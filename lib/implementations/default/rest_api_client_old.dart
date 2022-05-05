import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:rest_api_client/rest_api_client.dart';
import 'dart:async';
import 'dart:io';
import 'package:dio/adapter.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:storage_repository/storage_repository.dart';

///Basic implementation of IRestApiClient interface
///Provides a way to communicate with rest api,
///manages exceptions that may occure and also
///manages the authorization logic with jwt and refresh token
class RestApiClientOld extends DioMixin implements IRestApiClientOld {
  ///Defines options for handling exceptions per request
  ///Any direct changes to this instances properties
  ///are discarded after the response is handled
  @override
  ExceptionOptions exceptionOptions = ExceptionOptions();

  ///Provides a way for the user to listen to any
  ///RestApiClient exceptions that might happen during
  ///the execution of requests
  @override
  StreamController<BaseException> exceptions = StreamController<BaseException>.broadcast();

  ///Provides an interface for storing tokens to a
  ///secure storage so they are available on app restart
  late IStorageRepository _storageRepository;

  ///Provides an interface for storing cached data
  late IStorageRepository _cachedStorageRepository;

  ///Use this class to provide configuration
  ///for your RestApiClient instance
  final RestApiClientOptionsOld restApiClientOptions;

  late DioConnectivityRequestRetrier _dioConnectivityRequestRetrier;

  ///Customize logging options for requests/responses
  final LoggingOptions loggingOptions;

  ///Get jwt from storage
  Future<String> get jwt async => await _storageRepository.get(RestApiClientKeys.jwt);

  ///Get refresh token from storage
  Future<String> get refreshToken async => await _storageRepository.get(RestApiClientKeys.refreshToken);

  RestApiClientOld({
    required this.restApiClientOptions,
    this.loggingOptions = const LoggingOptions(),
  }) {
    _cachedStorageRepository = StorageRepository(
      key: RestApiClientKeys.cachedStorageKey,
      logPrefix: RestApiClientKeys.cachedStorageLogPrefix,
    );
    _storageRepository = SecureStorageRepository(
      key: RestApiClientKeys.storageKey,
      logPrefix: RestApiClientKeys.storageLogPrefix,
    );

    options = BaseOptions();
    httpClientAdapter = DefaultHttpClientAdapter();

    if (restApiClientOptions.keepRetryingOnNetworkError) {
      _dioConnectivityRequestRetrier = DioConnectivityRequestRetrier(dio: this);
    }

    options.baseUrl = restApiClientOptions.baseUrl;

    if (loggingOptions.logNetworkTraffic) {
      _configureDebugLogger();
    }

    _configureRefreshTokenInterceptor();
    if (restApiClientOptions.keepRetryingOnNetworkError) {
      _configureRetryOnConnectionChangeInterceptor();
    }

    if (restApiClientOptions.overrideBadCertificate) {
      (httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }
  }

  ///Method that should be called as soon as possible
  static Future<void> initFlutter() async {
    await StorageRepository.initFlutter();
  }

  ///Method that initializes RestApiClient instance
  @override
  Future<IRestApiClientOld> init() async {
    await _storageRepository.init();
    if (loggingOptions.logStorage) {
      await _storageRepository.log();
    }

    await _cachedStorageRepository.init();
    if (loggingOptions.logCacheStorage) {
      await _cachedStorageRepository.log();
    }

    final jwt = await _storageRepository.get(RestApiClientKeys.jwt);
    if (jwt != null && jwt is String && jwt.isNotEmpty) {
      _addOrUpdateHeader(key: RestApiClientKeys.authorization, value: 'Bearer $jwt');
    }

    return this;
  }

  ///Best to call this method to set free allocated
  ///resources that the RestApiClient instacte might
  ///have allocated
  @override
  Future dispose() async {
    exceptions.close();
  }

  ///Method that sets appropriate Accept language header
  @override
  void setAcceptLanguageHeader(String languageCode) {
    _addOrUpdateHeader(key: RestApiClientKeys.acceptLanguage, value: languageCode);
  }

  ///Method that adds Authorization header
  ///and initializes mechanism for managing
  ///refresh token logic
  @override
  Future<bool> addAuthorization({required String jwt, required String refreshToken}) async {
    final result = await _storageRepository.set(RestApiClientKeys.jwt, jwt);
    _addOrUpdateHeader(key: RestApiClientKeys.authorization, value: 'Bearer $jwt');

    return result && await _storageRepository.set(RestApiClientKeys.refreshToken, refreshToken);
  }

  ///Removes authorization header along with jwt
  ///and refreshToken from the secure storage
  @override
  Future<bool> removeAuthorization() async {
    final deleteJwtResult = await _storageRepository.delete(RestApiClientKeys.jwt);
    final deleteRefreshTokenResult = await _storageRepository.delete(RestApiClientKeys.jwt);

    options.headers.remove(RestApiClientKeys.authorization);

    return deleteJwtResult && deleteRefreshTokenResult;
  }

  @override
  Future<bool> isAuthorized() async {
    final containsAuthorizationHeader = options.headers.containsKey(RestApiClientKeys.authorization);
    final containsJwtInStorage = await _storageRepository.contains(RestApiClientKeys.jwt);
    final containsRefreshTokenInStorage = await _storageRepository.contains(RestApiClientKeys.refreshToken);

    return containsAuthorizationHeader && containsJwtInStorage && containsRefreshTokenInStorage;
  }

  @override
  Future clearSecureStorage() async {
    await _storageRepository.clear();
  }

  @override
  Future clearCacheStorage() async {
    await _cachedStorageRepository.clear();
  }

  void _addOrUpdateHeader({
    required String key,
    required String value,
  }) {
    if (options.headers.containsKey(key)) {
      options.headers.update(key, (v) => value);
    } else {
      options.headers.addAll({key: value});
    }
  }

  ///Configures the logging for requests/reponses
  void _configureDebugLogger() {
    interceptors.add(
      PrettyDioLogger(
        responseBody: loggingOptions.responseBody,
        requestBody: loggingOptions.requestBody,
        requestHeader: loggingOptions.requestHeader,
        request: loggingOptions.request,
        responseHeader: loggingOptions.responseHeader,
        compact: loggingOptions.compact,
        error: loggingOptions.error,
      ),
    );
  }

  ///Checks if the Authorization header is present
  bool get _usesAutorization => options.headers.containsKey(RestApiClientKeys.authorization);

  ///Provides a default implementation for
  ///managing the refreshing of the jwt by
  ///calling the appropriate api endpoint
  Future refreshTokenCallback(DioError error) async {
    try {
      if (restApiClientOptions.resolveJwt != null && restApiClientOptions.resolveRefreshToken != null) {
        // ignore: deprecated_member_use
        interceptors.requestLock.lock();
        // ignore: deprecated_member_use
        interceptors.responseLock.lock();

        final requestOptions = error.requestOptions;

        final dio = Dio(BaseOptions()
          ..baseUrl = restApiClientOptions.baseUrl
          ..contentType = Headers.jsonContentType);

        if (restApiClientOptions.overrideBadCertificate) {
          (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
            client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
            return client;
          };
        }

        final response = await dio.post(
          restApiClientOptions.refreshTokenEndpoint,
          data: {restApiClientOptions.refreshTokenParameterName: await refreshToken},
        );

        final jwt = restApiClientOptions.resolveJwt!(response);
        final rToken = restApiClientOptions.resolveRefreshToken!(response);

        await addAuthorization(jwt: jwt, refreshToken: rToken);

        //Set for current request
        if (requestOptions.headers.containsKey(RestApiClientKeys.authorization)) {
          requestOptions.headers.update(RestApiClientKeys.authorization, (v) => 'Bearer $jwt');
        } else {
          requestOptions.headers.addAll({RestApiClientKeys.authorization: 'Bearer $jwt'});
        }

        // ignore: deprecated_member_use
        interceptors.requestLock.unlock();
        // ignore: deprecated_member_use
        interceptors.responseLock.unlock();

        exceptionOptions.reset();

        return await request(
          requestOptions.path,
          cancelToken: requestOptions.cancelToken,
          data: requestOptions.data,
          onReceiveProgress: requestOptions.onReceiveProgress,
          onSendProgress: requestOptions.onSendProgress,
          queryParameters: requestOptions.queryParameters,
          options: Options(
            method: requestOptions.method,
            sendTimeout: requestOptions.sendTimeout,
            receiveTimeout: requestOptions.receiveTimeout,
            extra: requestOptions.extra,
            headers: requestOptions.headers,
            responseType: requestOptions.responseType,
            contentType: requestOptions.contentType,
            validateStatus: requestOptions.validateStatus,
            receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
            followRedirects: requestOptions.followRedirects,
            maxRedirects: requestOptions.maxRedirects,
            requestEncoder: requestOptions.requestEncoder,
            responseDecoder: requestOptions.responseDecoder,
            listFormat: requestOptions.listFormat,
          ),
        );
      }
    } catch (e) {
      // ignore: deprecated_member_use
      interceptors.requestLock.unlock();
      // ignore: deprecated_member_use
      interceptors.responseLock.unlock();

      throw e;
    }
  }

  ///Handles HttpStatus code 401 and checks
  ///if the token needs to be refreshed
  void _configureRefreshTokenInterceptor() {
    interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, handler) {
          options.extra.addAll({'showInternalServerErrors': exceptionOptions.showInternalServerErrors});
          options.extra.addAll({'showNetworkErrors': exceptionOptions.showNetworkErrors});
          options.extra.addAll({'showValidationErrors': exceptionOptions.showValidationErrors});

          return handler.next(options);
        },
        onResponse: (Response response, handler) {
          exceptionOptions.reset();

          return handler.next(response);
        },
        onError: (DioError error, handler) async {
          if (_usesAutorization) {
            if (error.response?.statusCode == HttpStatus.unauthorized) {
              try {
                return handler.resolve(await refreshTokenCallback(error));
              } catch (e) {
                print(e);
              }
            }
          }

          _handleException(_getExceptionFromDioError(error), error.requestOptions.extra);
          exceptionOptions.reset();

          return handler.next(error);
        },
      ),
    );
  }

  ///Handles retrying request when the device is reconnected to the internet
  void _configureRetryOnConnectionChangeInterceptor() {
    interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, handler) {
          options.extra.addAll({'keepRetryingOnNetworkError': restApiClientOptions.keepRetryingOnNetworkError});

          return handler.next(options);
        },
        onError: (DioError error, handler) async {
          if (_shouldRetryOnConnectionChange(error) && error.requestOptions.extra['keepRetryingOnNetworkError']) {
            try {
              return handler.resolve(await _dioConnectivityRequestRetrier.scheduleRequestRetry(error.requestOptions));
            } catch (e) {
              print(e);
            }
          }

          // Let the error pass through if it's not the error we're looking for
          return handler.next(error);
        },
      ),
    );
  }

  bool _shouldRetryOnConnectionChange(DioError error) => error.type == DioErrorType.other && error.error != null && error.error is SocketException;

  ///Resolves the instance of appropriate
  ///RestApiClient exception from DioError
  BaseException _getExceptionFromDioError(DioError error) {
    if (error.type == DioErrorType.response) {
      switch (error.response?.statusCode) {
        case HttpStatus.internalServerError:
          return ServerErrorException();
        case HttpStatus.badGateway:
          return ServerErrorException();
        case HttpStatus.notFound:
          return ValidationException.multipleFields(validationMessages: getValidationMessages(error));
        case HttpStatus.badRequest:
          return ValidationException.multipleFields(validationMessages: getValidationMessages(error));
        case HttpStatus.unauthorized:
          return UnauthorizedException();
        case HttpStatus.forbidden:
          return ForbiddenException();
        default:
          return BaseException();
      }
    } else {
      return NetworkErrorException();
    }
  }

  ///Resolves validation errors from DioError response
  Map<String, List<String>> getValidationMessages(DioError error) {
    try {
      if (error.response?.data != null) {
        Map<String, List<String>> errorsMap = {};

        if (restApiClientOptions.resolveValidationErrorsMap != null) {
          errorsMap = restApiClientOptions.resolveValidationErrorsMap!(error.response);
        } else {
          error.response!.data['validationErrors']?.forEach((key, value) => errorsMap[key] = value?.map<String>((x) => x as String)?.toList());
          if (error.response!.data['errors'] != null) {
            final errors = MapEntry<String, List<String>>('', error.response!.data['errors']?.map<String>((error) => error as String)?.toList() ?? ['']);
            errorsMap.addAll(Map.fromEntries([errors]));
          }
        }

        return errorsMap;
      }
    } catch (e) {
      print(e);
    }
    return {};
  }

  ///Checks if the exception should be inserted
  ///into the exceptions stream
  void _handleException(BaseException exception, Map<String, dynamic> extra) {
    if (exception is NetworkErrorException) {
      if (extra['showNetworkErrors'] ?? false) exceptions.add(exception);
    } else if (exception is ServerErrorException) {
      if (extra['showInternalServerErrors'] ?? false) exceptions.add(exception);
    } else if (exception is ValidationException) {
      if (extra['showValidationErrors'] ?? false) exceptions.add(exception);
    } else {
      exceptions.add(exception);
    }
  }

  /// Handy method to make http GET request and cache reponse data
  @override
  Future<Response<T>> getAndCache<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final response = await request<T>(
      path,
      queryParameters: queryParameters,
      options: DioMixin.checkOptions('GET', options),
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );

    await _cacheResponse(response);

    return response;
  }

  /// Handy method to make http GET request
  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool cache = false,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final response = await request<T>(
      path,
      queryParameters: queryParameters,
      options: DioMixin.checkOptions('GET', options),
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );

    if (restApiClientOptions.cacheResponse) {
      await _cacheResponse(response);
    }

    return response;
  }

  /// Handy method to make http POST request and cached response data
  @override
  Future<Response<T>> postAndCache<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final response = await request<T>(
      path,
      data: data,
      options: DioMixin.checkOptions('POST', options),
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    await _cacheResponse(response);

    return response;
  }

  /// Handy method to make http POST request
  @override
  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final response = await request<T>(
      path,
      data: data,
      options: DioMixin.checkOptions('POST', options),
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    if (restApiClientOptions.cacheResponse) {
      await _cacheResponse(response);
    }

    return response;
  }

  Future<Response<T>> getCached<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final requestOptions = RequestOptions(
      path: path,
      queryParameters: queryParameters,
      headers: super.options.headers,
    );

    return Response(
      requestOptions: requestOptions,
      data: await _getDataFromCache(requestOptions),
    );
  }

  Future<Response<T>> postCached<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final requestOptions = RequestOptions(
      path: path,
      queryParameters: queryParameters,
      data: data,
      headers: super.options.headers,
    );

    return Response(
      requestOptions: requestOptions,
      data: await _getDataFromCache(requestOptions),
    );
  }

  Future _cacheResponse(Response response) async {
    final cacheKey = _generateCacheKey(response.requestOptions);

    await _cachedStorageRepository.set(cacheKey, response.data);
  }

  Future<dynamic> _getDataFromCache(RequestOptions options) async {
    final cacheKey = _generateCacheKey(options);

    return await _cachedStorageRepository.get(cacheKey);
  }

  String _generateCacheKey(RequestOptions options) {
    final String authorization = options.headers.containsKey(RestApiClientKeys.authorization) ? options.headers[RestApiClientKeys.authorization] : '';
    final queryParametersSerialized = options.queryParameters.isNotEmpty ? json.encode(options.queryParameters) : '';
    final dataSerialized = (options.data != null && options.data.isNotEmpty) ? json.encode(options.data) : '';

    final key = '$queryParametersSerialized$dataSerialized$authorization';

    return '${options.path} - ${md5.convert(utf8.encode(key)).toString()}';
  }
}
