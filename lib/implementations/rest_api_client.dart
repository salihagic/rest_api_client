import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rest_api_client/rest_api_client.dart';
import 'package:storage_repository/storage_repository.dart';

class RestApiClient extends DioMixin implements IRestApiClient {
  @override
  late IStorageRepository storageRepository;
  @override
  late RestApiClientExceptionOptions exceptionOptions;
  @override
  StreamController<RestApiClientException> exceptions = StreamController<RestApiClientException>.broadcast();
  late RestApiClientOptions restApiClientOptions;

  RestApiClient({
    required this.storageRepository,
    required this.exceptionOptions,
    required this.restApiClientOptions,
  }) {
    options ??= BaseOptions();

    if (restApiClientOptions.logNetworkTraffic) {
      _configureDebugLogger();
    }

    _configureRefreshTokenInterceptor();
  }

  @override
  Future<IRestApiClient> init() async {
    final jwt = await storageRepository.get(RestApiClientKeys.jwt);
    if (jwt != null) {
      _addOrUpdateHeader(key: RestApiClientKeys.authorization, value: 'Bearer $jwt');
    }

    return this;
  }

  @override
  Future dispose() async {
    exceptions.close();
  }

  @override
  void setAcceptLanguageHeader(String languageCode) {
    _addOrUpdateHeader(key: RestApiClientKeys.acceptLanguage, value: languageCode);
  }

  @override
  Future<bool> addAuthorization({required String jwt, required String refreshToken}) async {
    final result = await storageRepository.set(RestApiClientKeys.jwt, jwt);
    _addOrUpdateHeader(key: RestApiClientKeys.authorization, value: 'Bearer $jwt');

    return result && await storageRepository.set(RestApiClientKeys.refreshToken, refreshToken);
  }

  Future<bool> removeAuthorization() async {
    final deleteJwtResult = await storageRepository.delete(RestApiClientKeys.jwt);
    final deleteRefreshTokenResult = await storageRepository.delete(RestApiClientKeys.jwt);

    options.headers.remove(RestApiClientKeys.jwt);
    options.headers.remove(RestApiClientKeys.refreshToken);

    return deleteJwtResult && deleteRefreshTokenResult;
  }

  Future<String> _getRefreshToken() async {
    return await storageRepository.get(RestApiClientKeys.refreshToken);
  }

  void _addOrUpdateHeader({
    required String key,
    required String value,
  }) {
    if (options.headers.containsKey(key)) {
      options.headers.update(key, (v) => value);
    } else {
      options.headers.addAll({
        key: value
      });
    }
  }

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

  bool get _usesAutorization => options.headers.containsKey(RestApiClientKeys.jwt);

  Future refreshTokenCallback(DioError error) async {
    interceptors.requestLock.lock();
    interceptors.responseLock.lock();

    final options = error.response.request;

    final response = await Dio(BaseOptions()
          ..baseUrl = restApiClientOptions.baseUrl
          ..contentType = Headers.jsonContentType)
        .post(
      restApiClientOptions.refreshTokenEndpoint,
      data: {
        restApiClientOptions.refreshTokenParameterName: _getRefreshToken()
      },
    );

    final jwt = restApiClientOptions.resolveRefreshToken!(response);
    final refreshToken = restApiClientOptions.resolveJwt!(response);

    addAuthorization(jwt: jwt, refreshToken: refreshToken);

    //Set for current request
    if (options.headers.containsKey(RestApiClientKeys.authorization)) {
      options.headers.update(RestApiClientKeys.authorization, (v) => 'Bearer $jwt');
    } else {
      options.headers.addAll({
        RestApiClientKeys.authorization: 'Bearer $jwt'
      });
    }

    interceptors.requestLock.unlock();
    interceptors.responseLock.unlock();

    return request(options.path, options: options);
  }

  void _configureRefreshTokenInterceptor() {
    interceptors.add(
      InterceptorsWrapper(
        onResponse: (Response response) {
          exceptionOptions.reset();

          return response;
        },
        onError: (DioError error) async {
          if (_usesAutorization) {
            if (error.response?.statusCode == HttpStatus.unauthorized) {
              try {
                return refreshTokenCallback(error);
              } catch (e) {
                print(e);
              }
            }

            _handleException(_getExceptionFromDioError(error));
            exceptionOptions.reset();
          }

          return error;
        },
      ),
    );
  }

  RestApiClientException _getExceptionFromDioError(DioError error) {
    if (error.type == DioErrorType.RESPONSE) {
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

  Map<String, List<String>> getValidationMessages(DioError error) {
    try {
      if (error.response?.data != null) {
        var errorsMap = {};

        if (restApiClientOptions.resolveValidationErrorsMap != null) {
          errorsMap = restApiClientOptions.resolveValidationErrorsMap!(error);
        } else if (error.response.data is String) {
          errorsMap = json.decode(error.response.data)['validationErrors'];
        } else {
          errorsMap = error.response.data['validationErrors'];
        }

        final Map<String, List<String>> result = {};

        errorsMap.forEach((key, value) {
          result[key] = value?.map<String>((x) => x as String)?.toList();
        });

        return result;
      }
    } catch (e) {
      print(e);
    }
    return {};
  }

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
