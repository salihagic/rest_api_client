import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rest_api_client/rest_api_client.dart';
import 'package:storage_repository/storage_repository.dart';

abstract class IRestApiClient extends DioMixin {
  late IStorageRepository storageRepository;
  late RestApiClientExceptionOptions exceptionOptions;
  late StreamController<RestApiClientException> exceptions;

  Future<IRestApiClient> init();
  Future dispose();
  void setAcceptLanguageHeader(String languageCode);
  Future<bool> addAuthorization({required String jwt, required String refreshToken});
  Future<bool> removeAuthorization();
}
