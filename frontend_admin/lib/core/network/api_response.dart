/// Envoltorio estándar de respuestas del backend Flask.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  final bool success;
  final String message;
  final T? data;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    final rawData = json['data'];
    return ApiResponse<T>(
      success: json['success'] == true,
      message: (json['message'] as String?) ?? '',
      data: fromJsonT != null && rawData != null ? fromJsonT(rawData) : rawData as T?,
    );
  }
}
