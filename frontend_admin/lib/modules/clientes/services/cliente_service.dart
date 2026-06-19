import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/api_query.dart';
import '../models/cliente_model.dart';

final clienteServiceProvider = Provider<ClienteService>((ref) {
  return ClienteService(ref.watch(apiClientProvider));
});

class ClienteService {
  ClienteService(this._client);
  final ApiClient _client;

  Future<PaginatedResponse<ClienteModel>> listar({
    int page = 1,
    int perPage = 50,
    String? search,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.clientes,
      queryParameters: apiQuery({
        'page': page,
        'per_page': perPage,
        'search': search,
      }),
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return PaginatedResponse.fromJson(res.data!, ClienteModel.fromJson);
  }

  Future<ClienteModel> crear(Map<String, dynamic> data) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.clientes,
      data: data,
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return ClienteModel.fromJson(res.data!);
  }

  Future<ClienteModel> actualizar(int id, Map<String, dynamic> data) async {
    final res = await _client.put<Map<String, dynamic>>(
      ApiConstants.cliente(id),
      data: data,
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return ClienteModel.fromJson(res.data!);
  }

  Future<void> eliminar(int id) async {
    await _client.delete('${ApiConstants.clientes}/$id');
  }
}
