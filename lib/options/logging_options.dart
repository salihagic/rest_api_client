///Options to customize logging of http requests/responses
class LoggingOptions {
  ///Toggle logging of your requests and responses
  ///to the console while debugging
  final bool logNetworkTraffic;

  /// Print request [Options]
  final bool request;

  /// Print request header [Options.headers]
  final bool requestHeader;

  /// Print request data [Options.data]
  final bool requestBody;

  /// Print [Response.data]
  final bool responseBody;

  /// Print [Response.headers]
  final bool responseHeader;

  /// Print error message
  final bool error;

  /// Print compact json response
  final bool compact;

  /// Print storage content
  final bool logStorage;

  /// Print cache storage content
  final bool logCacheStorage;

  const LoggingOptions({
    this.logNetworkTraffic = true,
    this.request = true,
    this.requestHeader = true,
    this.requestBody = true,
    this.responseBody = true,
    this.responseHeader = true,
    this.error = true,
    this.compact = true,
    this.logStorage = true,
    this.logCacheStorage = true,
  });
}
