import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/api_query.dart';
import '../models/pago_model.dart';

final pagoServiceProvider = Provider<PagoService>((ref) {
  return PagoService(ref.watch(apiClientProvider));
});

class PagoService {
  PagoService(this._client);
  final ApiClient _client;

  Future<PaginatedResponse<PagoModel>> listar({int perPage = 50}) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.pagos,
      queryParameters: apiQuery({'page': 1, 'per_page': perPage}),
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return PaginatedResponse.fromJson(res.data!, PagoModel.fromJson);
  }

  Future<PagoModel> crear(Map<String, dynamic> data) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.pagos,
      data: data,
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return PagoModel.fromJson(res.data!);
  }
}
