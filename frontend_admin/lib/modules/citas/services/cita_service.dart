import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/api_query.dart';
import '../models/cita_model.dart';

final citaServiceProvider = Provider<CitaService>((ref) {
  return CitaService(ref.watch(apiClientProvider));
});

class CitaService {
  CitaService(this._client);
  final ApiClient _client;

  Future<PaginatedResponse<CitaModel>> listar({
    int page = 1,
    int perPage = 100,
    String? fecha,
    String? estado,
    int? empleadoId,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.citas,
      queryParameters: apiQuery({
        'page': page,
        'per_page': perPage,
        'fecha': fecha,
        'estado': estado,
        'empleado_id': empleadoId,
      }),
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return PaginatedResponse.fromJson(res.data!, CitaModel.fromJson);
  }

  Future<CitaModel> crear(Map<String, dynamic> data) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.citas,
      data: data,
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return CitaModel.fromJson(res.data!);
  }

  Future<CitaModel> actualizar(int id, Map<String, dynamic> data) async {
    final res = await _client.put<Map<String, dynamic>>(
      ApiConstants.cita(id),
      data: data,
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return CitaModel.fromJson(res.data!);
  }

  Future<void> eliminar(int id) async {
    await _client.delete('${ApiConstants.citas}/$id');
  }
}
