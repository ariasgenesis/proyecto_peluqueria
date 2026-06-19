class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  final List<T> data;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawList = json['data'];
    final List<dynamic> raw;
    if (rawList is List) {
      raw = rawList;
    } else {
      raw = [];
    }

    return PaginatedResponse(
      data: raw.map((e) => fromJsonT(e as Map<String, dynamic>)).toList(),
      total: _asInt(json['total']) ?? raw.length,
      page: _asInt(json['page']) ?? 1,
      perPage: _asInt(json['per_page']) ?? raw.length,
      totalPages: _asInt(json['total_pages']) ?? 1,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}
