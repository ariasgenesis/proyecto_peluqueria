import 'package:flutter/foundation.dart';

/// Resuelve la URL base del API según entorno y plataforma.
String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) {
    return fromEnv.endsWith('/') ? fromEnv.substring(0, fromEnv.length - 1) : fromEnv;
  }

  if (kIsWeb) {
    final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
    final scheme = Uri.base.scheme.isNotEmpty ? Uri.base.scheme : 'http';
    return '$scheme://$host:4000';
  }

  return 'http://localhost:4000';
}
