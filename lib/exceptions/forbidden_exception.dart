import 'package:rest_api_client/rest_api_client.dart';

///Derived exception class that represents
///any server error
class ForbiddenException extends BaseException {
  ForbiddenException({
    bool silent = false,
    List<String> messages = const [],
  }) : super(
          silent: silent,
          messages: messages,
        );

  ///Method to be called in debugging mode to
  ///check the contents of the exception
  @override
  String toString() => 'FORBIDDEN EXCEPTION: $messages';
}
