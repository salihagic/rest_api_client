import 'package:rest_api_client/rest_api_client.dart';

///Derived exception class that represents
///any server error
class UnauthorizedException extends BaseException {
  UnauthorizedException({
    bool silent = false,
    List<String> messages = const [],
  }) : super(
          silent: silent,
          messages: messages,
        );

  ///Method to be called in debugging mode to
  ///check the contents of the exception
  @override
  String toString() => 'UNAUTHORIZED EXCEPTION: $messages';
}
