import 'package:rest_api_client/exceptions/base_exception.dart';

///Derived exception class that represents
///any network related error
class NetworkErrorException extends BaseException {
  NetworkErrorException({
    bool silent = false,
    List<String> messages = const [],
  }) : super(
          silent: silent,
          messages: messages,
        );

  ///Method to be called in debugging mode to
  ///check the contents of the exception
  @override
  String toString() => 'NETWORK ERROR EXCEPTION: $messages';
}
