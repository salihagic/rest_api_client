class RestApiClientException implements Exception {
  bool silent;
  List<String> messages = [];

  RestApiClientException({
    this.silent = false,
    this.messages = const [],
  });

  @override
  String toString() => 'REST API CLIENT EXCEPTION: ${this.messages}';
}
