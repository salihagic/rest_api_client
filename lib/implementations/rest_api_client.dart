import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rest_api_client/rest_api_client.dart';
import 'package:storage_repository/storage_repository.dart';

///Basic implementation of IRestApiClient interface
///Provides a way to communicate with rest api,
///manages exceptions that may occure and also
///manages the authorization logic with jwt and refresh token
class RestApiClient extends DioMixin implements IRestApiClient {
  ///Defines options for handling exceptions per request
  ///Any direct changes to this instances properties
  ///are discarded after the response is handled
  @override
  RestApiClientExceptionOptions exceptionOptions = RestApiClientExceptionOptions();

  ///Provides a way for the user to listen to any
  ///RestApiClient exceptions that might happen during
  ///the execution of requests
  @override
  StreamController<RestApiClientException> exceptions = StreamController<RestApiClientException>.broadcast();

  ///Provides an interface for storing tokens to a
  ///secure storage so they are available on app restart
  IStorageRepository storageRepository = SecureStorageRepository();

  ///Use this class to provide configuration
  ///for your RestApiClient instance
  RestApiClientOptions restApiClientOptions;

  RestApiClient({
    @required this.restApiClientOptions,
  }) {
    options = BaseOptions();
    httpClientAdapter = DefaultHttpClientAdapter();

    options.baseUrl = restApiClientOptions.baseUrl;

    if (restApiClientOptions.logNetworkTraffic) {
      _configureDebugLogger();
    }

    _configureRefreshTokenInterceptor();
  }

  ///Method that initializes RestApiClient instance
  @override
  Future<IRestApiClient> init() async {
    await storageRepository.init();

    final jwt = await storageRepository.get(RestApiClientKeys.jwt);
    if (jwt != null) {
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
  Future<bool> addAuthorization({@required String jwt, @required String refreshToken}) async {
    final result = await storageRepository.set(RestApiClientKeys.jwt, jwt);
    _addOrUpdateHeader(key: RestApiClientKeys.authorization, value: 'Bearer $jwt');

    return result && await storageRepository.set(RestApiClientKeys.refreshToken, refreshToken);
  }

  ///Removes authorization header along with jwt
  ///and refreshToken from the secure storage
  @override
  Future<bool> removeAuthorization() async {
    final deleteJwtResult = await storageRepository.delete(RestApiClientKeys.jwt);
    final deleteRefreshTokenResult = await storageRepository.delete(RestApiClientKeys.jwt);

    options.headers.remove(RestApiClientKeys.authorization);

    return deleteJwtResult && deleteRefreshTokenResult;
  }

  ///Provides information if the current instance
  ///of RestApiClient contains Authorization header
  @override
  Future<bool> isAuthorized() async {
    final containsAuthorizationHeader = options.headers.containsKey(RestApiClientKeys.authorization);
    final containsJwtInStorage = await storageRepository.contains(RestApiClientKeys.jwt);
    final containsRefreshTokenInStorage = await storageRepository.contains(RestApiClientKeys.refreshToken);

    return containsAuthorizationHeader && containsJwtInStorage && containsRefreshTokenInStorage;
  }

  ///Loads the refresh token from secure storage
  Future<String> _getRefreshToken() async {
    final refreshToken = await storageRepository.get(RestApiClientKeys.refreshToken);
    return refreshToken;
  }

  ///Adds or updates the header under a given key
  void _addOrUpdateHeader({
    @required String key,
    @required String value,
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
        responseBody: true,
        requestBody: true,
        requestHeader: true,
        request: true,
        responseHeader: true,
      ),
    );
  }

  ///Checks if the Authorization header is present
  bool get _usesAutorization => options.headers.containsKey(RestApiClientKeys.authorization);

  ///Provides a default implementation for
  ///managing the refreshing of the jwt by
  ///calling the appropriate api endpoint
  Future refreshTokenCallback(DioError error) async {
    interceptors.requestLock.lock();
    interceptors.responseLock.lock();

    final options = error.requestOptions;

    final response = await Dio(BaseOptions()
          ..baseUrl = restApiClientOptions.baseUrl
          ..contentType = Headers.jsonContentType)
        .post(
      restApiClientOptions.refreshTokenEndpoint,
      data: {restApiClientOptions.refreshTokenParameterName: await _getRefreshToken()},
    );

    final jwt = restApiClientOptions.resolveJwt(response);
    final refreshToken = restApiClientOptions.resolveRefreshToken(response);

    await addAuthorization(jwt: jwt, refreshToken: refreshToken);

    //Set for current request
    if (options.headers.containsKey(RestApiClientKeys.authorization)) {
      options.headers.update(RestApiClientKeys.authorization, (v) => 'Bearer $jwt');
    } else {
      options.headers.addAll({RestApiClientKeys.authorization: 'Bearer $jwt'});
    }

    interceptors.requestLock.unlock();
    interceptors.responseLock.unlock();

    return request(options.path);
  }

  ///Handles HttpStatus code 401 and checks
  ///if the token needs to be refreshed
  void _configureRefreshTokenInterceptor() {
    interceptors.add(
      InterceptorsWrapper(
        onResponse: (Response response, handler) {
          exceptionOptions.reset();

          return handler.next(response);
        },
        onError: (DioError error, handler) async {
          if (_usesAutorization) {
            if (error.response?.statusCode == HttpStatus.unauthorized) {
              try {
                return refreshTokenCallback(error);
              } catch (e) {
                print(e);
              }
            }
          }

          _handleException(_getExceptionFromDioError(error));
          exceptionOptions.reset();

          return handler.next(error);
        },
      ),
    );
  }

  ///Resolves the instance of appropriate
  ///RestApiClient exception from DioError
  RestApiClientException _getExceptionFromDioError(DioError error) {
    if (error.type == DioErrorType.response) {
      switch (error.response?.statusCode) {
        case HttpStatus.internalServerError:
          return ServerErrorException();
        case HttpStatus.notFound:
        case HttpStatus.badGateway:
          return ServerErrorException();
        case HttpStatus.badRequest:
          return ValidationException.multipleFields(
            validationMessages: getValidationMessages(error),
          );
        default:
          return RestApiClientException();
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
          errorsMap = restApiClientOptions.resolveValidationErrorsMap(error.response);
        } else {
          error.response.data['validationErrors']?.forEach((key, value) => errorsMap[key] = value?.map<String>((x) => x as String)?.toList());
          if (error.response.data['errors'] != null) {
            final errors = MapEntry<String, List<String>>('', error.response.data['errors']?.map<String>((error) => error as String)?.toList() ?? ['']);
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
  void _handleException(RestApiClientException exception) {
    if (exception is NetworkErrorException && exceptionOptions.showNetworkErrors) {
      exceptions.add(exception);
    } else if (exception is ServerErrorException && exceptionOptions.showInternalServerErrors) {
      exceptions.add(exception);
    } else if (exception is ValidationException && exceptionOptions.showValidationErrors) {
      exceptions.add(exception);
    } else {
      exceptions.add(exception);
    }
  }
}
