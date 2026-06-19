import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/api_query.dart';
import '../models/servicio_model.dart';

final servicioServiceProvider = Provider<ServicioService>((ref) {
  return ServicioService(ref.watch(apiClientProvider));
});

class ServicioService {
  ServicioService(this._client);
  final ApiClient _client;

  Future<PaginatedResponse<ServicioModel>> listar({
    int perPage = 50,
    String? search,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.servicios,
      queryParameters: apiQuery({
        'page': 1,
        'per_page': perPage,
        'search': search,
        'include_deleted': true,
      }),
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return PaginatedResponse.fromJson(res.data!, ServicioModel.fromJson);
  }

  Future<ServicioModel> crear(Map<String, dynamic> data) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.servicios,
      data: data,
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return ServicioModel.fromJson(res.data!);
  }

  Future<ServicioModel> actualizar(int id, Map<String, dynamic> data) async {
    final res = await _client.put<Map<String, dynamic>>(
      ApiConstants.servicio(id),
      data: data,
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return ServicioModel.fromJson(res.data!);
  }

  Future<void> eliminar(int id) async {
    await _client.delete('${ApiConstants.servicios}/$id');
  }
}
