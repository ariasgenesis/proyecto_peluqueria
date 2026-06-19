import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/api_query.dart';
import '../models/movimiento_model.dart';

final movimientoServiceProvider = Provider<MovimientoService>((ref) {
  return MovimientoService(ref.watch(apiClientProvider));
});

class MovimientoService {
  MovimientoService(this._client);
  final ApiClient _client;

  Future<PaginatedResponse<MovimientoModel>> listar({int perPage = 50, String? search}) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.movimientos,
      queryParameters: apiQuery({
        'page': 1,
        'per_page': perPage,
        'search': search,
      }),
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return PaginatedResponse.fromJson(res.data!, MovimientoModel.fromJson);
  }
}
