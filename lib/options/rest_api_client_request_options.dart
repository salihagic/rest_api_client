import 'package:dio/dio.dart';

class RestApiClientRequestOptions {
  Map<String, dynamic>? headers;
  String? contentType;
  bool silentException;

  RestApiClientRequestOptions({
    this.headers,
    this.contentType,
    this.silentException = false,
  });

  Options toOptions() {
    return Options(
      headers: headers,
      contentType: contentType,
    );
  }
}
