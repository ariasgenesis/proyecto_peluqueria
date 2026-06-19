import 'package:dio/dio.dart';

typedef TokenProvider = String? Function();
typedef OnUnauthorized = void Function();

/// Interceptor JWT: adjunta Bearer y maneja 401 globalmente.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.getToken,
    this.onUnauthorized,
  });

  final TokenProvider getToken;
  final OnUnauthorized? onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}
