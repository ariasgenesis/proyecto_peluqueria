import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/api_query.dart';
import '../models/empleado_model.dart';

final empleadoServiceProvider = Provider<EmpleadoService>((ref) {
  return EmpleadoService(ref.watch(apiClientProvider));
});

class EmpleadoService {
  EmpleadoService(this._client);
  final ApiClient _client;

  Future<PaginatedResponse<EmpleadoModel>> listar({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.empleados,
      queryParameters: apiQuery({
        'page': page,
        'per_page': perPage,
        'search': search,
      }),
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return PaginatedResponse.fromJson(res.data!, EmpleadoModel.fromJson);
  }

  Future<EmpleadoModel> crear(Map<String, dynamic> data) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.empleados,
      data: data,
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return EmpleadoModel.fromJson(res.data!);
  }

  Future<EmpleadoModel> actualizar(int id, Map<String, dynamic> data) async {
    final res = await _client.put<Map<String, dynamic>>(
      ApiConstants.empleado(id),
      data: data,
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return EmpleadoModel.fromJson(res.data!);
  }

  Future<void> eliminar(int id) async {
    await _client.delete('${ApiConstants.empleados}/$id');
  }
}
