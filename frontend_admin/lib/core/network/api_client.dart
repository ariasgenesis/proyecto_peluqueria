import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../errors/api_exception.dart';
import '../storage/token_storage.dart';
import 'api_interceptor.dart';
import 'api_response.dart';
import 'unauthorized_bridge.dart';

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final bridge = ref.watch(unauthorizedBridgeProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      followRedirects: true,
      validateStatus: (status) => status != null && status < 500,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      getToken: () => tokenStorage.getToken(),
      onUnauthorized: bridge.notify,
    ),
  );

  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    error: true,
  ));

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    return _request(
      () => _dio.get(path, queryParameters: queryParameters),
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? fromJson,
  }) async {
    return _request(
      () => _dio.post(path, data: data),
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? fromJson,
  }) async {
    return _request(
      () => _dio.put(path, data: data),
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? fromJson,
  }) async {
    return _request(
      () => _dio.delete(path, data: data),
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> _request<T>(
    Future<Response<dynamic>> Function() call, {
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final response = await call();
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw ApiException(
          message:
              'Respuesta inválida del servidor (${response.statusCode}). '
              'Verifique que el API esté en ${ApiConstants.baseUrl}',
          statusCode: response.statusCode,
        );
      }
      final parsed = ApiResponse<T>.fromJson(body, fromJson);
      if (!parsed.success) {
        throw ApiException(
          message: parsed.message,
          statusCode: response.statusCode,
        );
      }
      return parsed;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
