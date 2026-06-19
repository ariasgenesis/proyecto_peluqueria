import 'package:dio/dio.dart';

import 'failure.dart';

class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  final String message;
  final int? statusCode;
  final Object? originalError;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;

    String message = 'Error de comunicación con el servidor';
    if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Tiempo de espera agotado';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'No se pudo conectar con el servidor';
    }

    return ApiException(
      message: message,
      statusCode: response?.statusCode,
      originalError: error,
    );
  }

  Failure toFailure() {
    if (statusCode == 401) {
      return UnauthorizedFailure(message);
    }
    if (statusCode != null && statusCode! >= 500) {
      return ServerFailure(message);
    }
    if (statusCode == 400 || statusCode == 422) {
      return ValidationFailure(message);
    }
    return ServerFailure(message);
  }

  @override
  String toString() => message;
}
