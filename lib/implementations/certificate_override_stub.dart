import 'package:dio/dio.dart';

void configureCertificateOverride(HttpClientAdapter adapter) {
  // No-op on platforms that don't support dart:io (e.g. web/WASM)
}
