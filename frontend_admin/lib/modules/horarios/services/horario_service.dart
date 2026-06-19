import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_client.dart';
import '../models/horario_model.dart';

final horarioServiceProvider = Provider<HorarioService>((ref) {
  return HorarioService(ref.watch(apiClientProvider));
});

class HorarioService {
  HorarioService(this._client);
  final ApiClient _client;

  Future<PaginatedResponse<HorarioModel>> listar({int perPage = 100}) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.horarios,
      queryParameters: {'page': 1, 'per_page': perPage},
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return PaginatedResponse.fromJson(res.data!, HorarioModel.fromJson);
  }

  Future<HorarioModel> crear(Map<String, dynamic> data) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.horarios,
      data: data,
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return HorarioModel.fromJson(res.data!);
  }

  Future<HorarioModel> actualizar(int id, Map<String, dynamic> data) async {
    final res = await _client.put<Map<String, dynamic>>(
      ApiConstants.horario(id),
      data: data,
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return HorarioModel.fromJson(res.data!);
  }

  Future<void> eliminar(int id) async {
    await _client.delete('${ApiConstants.horarios}/$id');
  }
}
