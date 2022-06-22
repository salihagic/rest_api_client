import 'package:dio/dio.dart';

class RestApiClientRequestOptions {
  Map<String, dynamic>? headers;
  String? contentType;

  RestApiClientRequestOptions({
    this.headers,
    this.contentType,
  });

  Options toOptions() {
    return Options(
      headers: headers,
      contentType: contentType,
    );
  }
}
