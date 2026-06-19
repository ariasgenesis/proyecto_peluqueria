import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../models/producto_model.dart';
import '../services/producto_service.dart';

final productoListControllerProvider =
    StateNotifierProvider<ProductoListController, AsyncValue<List<ProductoModel>>>((ref) {
  return ProductoListController(ref.watch(productoServiceProvider));
});

class ProductoListController extends StateNotifier<AsyncValue<List<ProductoModel>>> {
  ProductoListController(this._service) : super(const AsyncValue.loading()) {
    cargar();
  }

  final ProductoService _service;

  Future<void> cargar({String? search}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final res = await _service.listar(search: search);
      return res.data;
    });
  }

  Future<bool> guardar(ProductoModel p, {bool esNuevo = false}) async {
    try {
      if (esNuevo) {
        await _service.crear(p.toJson());
      } else {
        await _service.actualizar(p.idProducto, p.toJson());
      }
      await cargar();
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<bool> ajustarStock(
    int id,
    String tipo,
    Map<String, dynamic> body,
  ) async {
    try {
      switch (tipo) {
        case 'agregar':
          await _service.agregarStock(id, body);
        case 'descontar':
          await _service.descontarStock(id, body);
        case 'editar':
          await _service.editarStock(id, body);
      }
      await cargar();
      return true;
    } on ApiException {
      return false;
    }
  }
}
