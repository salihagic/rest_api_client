import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:rest_api_client/exceptions/base_exception.dart';
import 'package:rest_api_client/exceptions/forbidden_exception.dart';
import 'package:rest_api_client/exceptions/network_error_exception.dart';
import 'package:rest_api_client/exceptions/server_error_exception.dart';
import 'package:rest_api_client/exceptions/unauthorized_exception.dart';
import 'package:rest_api_client/exceptions/validation_exception.dart';
import 'package:rest_api_client/options/exception_options.dart';

class ExceptionHandler {
  final StreamController<BaseException> exceptions =
      StreamController<BaseException>.broadcast();
  final ExceptionOptions exceptionOptions;

  ExceptionHandler({
    required this.exceptionOptions,
  });

  Future handle(
    DioException e, {
    Map<String, dynamic> extra = const {},
    bool? silent,
  }) async {
    _handleException(_getExceptionFromDioError(e, silent ?? false), extra);
    exceptionOptions.reset();
  }

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

  BaseException _getExceptionFromDioError(DioException e, bool silent) {
    if (e.type == DioExceptionType.badResponse) {
      switch (e.response?.statusCode) {
        case HttpStatus.internalServerError:
          return ServerErrorException(silent: silent);
        case HttpStatus.badGateway:
          return ServerErrorException(silent: silent);
        case HttpStatus.notFound:
          return ValidationException.multipleFields(
              silent: silent, validationMessages: _getValidationMessages(e));
        case HttpStatus.unprocessableEntity:
          return ValidationException.multipleFields(
              silent: silent, validationMessages: _getValidationMessages(e));
        case HttpStatus.badRequest:
          return ValidationException.multipleFields(
              silent: silent, validationMessages: _getValidationMessages(e));
        case HttpStatus.unauthorized:
          return UnauthorizedException(silent: silent);
        case HttpStatus.forbidden:
          return ForbiddenException(silent: silent);
        default:
          return BaseException(silent: silent);
      }
    } else {
      return NetworkErrorException(silent: silent);
    }
  }

  Map<String, List<String>> _getValidationMessages(DioException error) {
    try {
      if (error.response?.data != null) {
        Map<String, List<String>> errorsMap = {};

        if (exceptionOptions.resolveValidationErrorsMap != null) {
          errorsMap =
              exceptionOptions.resolveValidationErrorsMap!(error.response);
        } else {
          error.response!.data['validationErrors']?.forEach((key, value) =>
              errorsMap[key] =
                  value?.map<String>((x) => x as String)?.toList());
          if (error.response!.data['errors'] != null) {
            final errors = MapEntry<String, List<String>>(
                '',
                error.response!.data['errors']
                        ?.map<String>((error) => error as String)
                        ?.toList() ??
                    ['']);
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
}
