import 'package:dio/dio.dart';

/// Options for configuring HTTP requests in the RestApiClient.
class RestApiClientRequestOptions {
  /// A map of headers to include with the request.
  ///
  /// This allows for customization of HTTP headers, such as
  /// authorization tokens, content types, or any other necessary
  /// headers that your API might require.
  Map<String, dynamic>? headers;

  /// The content type of the request.
  ///
  /// This specifies the media type of the resource being sent,
  /// allowing clients to communicate appropriately with the server.
  String? contentType;

  /// A flag to indicate whether to suppress exceptions.
  ///
  /// If set to true, errors during the request will not throw
  /// exceptions but instead can be handled gracefully, allowing
  /// the application to continue running without interruptions.
  bool silentException;

  /// Constructor for creating an instance of RestApiClientRequestOptions.
  ///
  /// The [headers] and [contentType] parameters are optional, while
  /// the [silentException] defaults to false, meaning exceptions
  /// will be thrown unless specified.
  RestApiClientRequestOptions({
    this.headers,
    this.contentType,
    this.silentException = false,
  });

  /// Converts the current request options to Dio's [Options] format.
  ///
  /// This method is useful for transforming the RestApiClientRequestOptions
  /// into a format that can be utilized by Dio when making HTTP requests.
  Options toOptions() {
    return Options(headers: headers, contentType: contentType);
  }
}
