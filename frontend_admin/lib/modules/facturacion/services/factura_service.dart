import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/api_query.dart';
import '../models/factura_model.dart';

final facturaServiceProvider = Provider<FacturaService>((ref) {
  return FacturaService(ref.watch(apiClientProvider));
});

class FacturaService {
  FacturaService(this._client);
  final ApiClient _client;

  Future<PaginatedResponse<FacturaModel>> listar({int perPage = 50}) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.facturas,
      queryParameters: apiQuery({'page': 1, 'per_page': perPage}),
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return PaginatedResponse.fromJson(res.data!, FacturaModel.fromJson);
  }

  Future<FacturaModel> crear(Map<String, dynamic> data) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.facturas,
      data: data,
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return FacturaModel.fromJson(res.data!);
  }

  Future<FacturaModel> actualizar(int id, Map<String, dynamic> data) async {
    final res = await _client.put<Map<String, dynamic>>(
      ApiConstants.factura(id),
      data: data,
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return FacturaModel.fromJson(res.data!);
  }

  Future<void> eliminar(int id, Map<String, dynamic> pinBody) async {
    await _client.delete(
      ApiConstants.factura(id),
      data: pinBody,
    );
  }
}
