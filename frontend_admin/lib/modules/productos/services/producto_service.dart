import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/api_query.dart';
import '../models/producto_model.dart';

final productoServiceProvider = Provider<ProductoService>((ref) {
  return ProductoService(ref.watch(apiClientProvider));
});

class ProductoService {
  ProductoService(this._client);
  final ApiClient _client;

  Future<PaginatedResponse<ProductoModel>> listar({
    int page = 1,
    int perPage = 50,
    String? search,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.productos,
      queryParameters: apiQuery({
        'page': page,
        'per_page': perPage,
        'search': search,
      }),
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return PaginatedResponse.fromJson(res.data!, ProductoModel.fromJson);
  }

  Future<PaginatedResponse<ProductoModel>> stockBajo({int perPage = 50}) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.productosStockBajo,
      queryParameters: apiQuery({'page': 1, 'per_page': perPage}),
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return PaginatedResponse.fromJson(res.data!, ProductoModel.fromJson);
  }

  Future<ProductoModel> crear(Map<String, dynamic> data) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.productos,
      data: data,
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return ProductoModel.fromJson(res.data!);
  }

  Future<ProductoModel> actualizar(int id, Map<String, dynamic> data) async {
    final res = await _client.put<Map<String, dynamic>>(
      ApiConstants.producto(id),
      data: data,
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return ProductoModel.fromJson(res.data!);
  }

  Future<void> eliminar(int id) async {
    await _client.delete(ApiConstants.producto(id));
  }

  Future<ProductoModel> agregarStock(int id, Map<String, dynamic> body) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.productoAgregarStock(id),
      data: body,
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return ProductoModel.fromJson(res.data!);
  }

  Future<ProductoModel> descontarStock(int id, Map<String, dynamic> body) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.productoDescontarStock(id),
      data: body,
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return ProductoModel.fromJson(res.data!);
  }

  Future<ProductoModel> editarStock(int id, Map<String, dynamic> body) async {
    final res = await _client.put<Map<String, dynamic>>(
      ApiConstants.productoEditarStock(id),
      data: body,
      fromJson: (j) => j as Map<String, dynamic>,
    );
    return ProductoModel.fromJson(res.data!);
  }
}
