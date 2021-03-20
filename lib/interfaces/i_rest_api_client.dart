import 'dart:async';
import 'package:dio/dio.dart';
import 'package:rest_api_client/rest_api_client.dart';

abstract class IRestApiClient extends DioMixin {
  late RestApiClientExceptionOptions exceptionOptions;
  late StreamController<RestApiClientException> exceptions;

  Future<IRestApiClient> init();
  Future dispose();
  void setAcceptLanguageHeader(String languageCode);
  Future<bool> addAuthorization(
      {required String jwt, required String refreshToken});
  Future<bool> removeAuthorization();
  Future<bool> isAuthorized();
}
