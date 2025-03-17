/// Options to customize logging of HTTP requests and responses.
class LoggingOptions {
  /// Toggle logging of network traffic to the console while debugging.
  ///
  /// If set to true, both requests and responses will be logged,
  /// providing visibility into network activity during development.
  final bool logNetworkTraffic;

  /// Print request options including the method, URL, and other related information.
  final bool request;

  /// Print the headers of the request ([Options.headers]).
  ///
  /// If set to true, request headers will be displayed in the logs.
  final bool requestHeader;

  /// Print the body of the request ([Options.data]).
  ///
  /// If true, the request payload will be logged.
  final bool requestBody;

  /// Print the body of the response ([Response.data]).
  ///
  /// If set to true, the data returned from the server will be logged.
  final bool responseBody;

  /// Print the headers of the response ([Response.headers]).
  ///
  /// If true, the headers returned from the server will be displayed in the logs.
  final bool responseHeader;

  /// Print error messages encountered during the HTTP request/response cycle.
  ///
  /// If set to true, any errors encountered will be logged for debugging purposes.
  final bool error;

  /// Print a compact JSON representation of the response.
  ///
  /// If true, the response will be logged in a compact JSON format,
  /// making it easier to read.
  final bool compact;

  /// Print content stored in local storage (e.g., shared preferences, local database).
  ///
  /// If true, the application will log the data stored in persistent storage.
  final bool logStorage;

  /// Print content stored in cache memory.
  ///
  /// If set to true, the contents of the cache storage will be displayed in the logs.
  final bool logCacheStorage;

  /// Constructor to initialize LoggingOptions with customizable settings.
  const LoggingOptions({
    this.logNetworkTraffic = true, // Default is true; logs network traffic.
    this.request = true, // Default is true; logs request options.
    this.requestHeader = true, // Default is true; logs request headers.
    this.requestBody = true, // Default is true; logs request body.
    this.responseBody = true, // Default is true; logs response body.
    this.responseHeader = true, // Default is true; logs response headers.
    this.error = true, // Default is true; logs errors.
    this.compact = true, // Default is true; logs compact JSON responses.
    this.logStorage = true, // Default is true; logs storage content.
    this.logCacheStorage = true, // Default is true; logs cache storage content.
  });
}
