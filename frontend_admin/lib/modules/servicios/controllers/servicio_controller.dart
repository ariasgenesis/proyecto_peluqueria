import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../models/servicio_model.dart';
import '../services/servicio_service.dart';

final servicioListControllerProvider =
    StateNotifierProvider<ServicioListController, AsyncValue<List<ServicioModel>>>((ref) {
  return ServicioListController(ref.watch(servicioServiceProvider));
});

class ServicioListController extends StateNotifier<AsyncValue<List<ServicioModel>>> {
  ServicioListController(this._service) : super(const AsyncValue.loading()) {
    cargar();
  }

  final ServicioService _service;

  Future<void> cargar() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final res = await _service.listar();
      return res.data;
    });
  }

  Future<bool> guardar(ServicioModel s, {bool esNuevo = false}) async {
    try {
      if (esNuevo) {
        await _service.crear(s.toJson());
      } else {
        await _service.actualizar(s.idServicio, s.toJson());
      }
      await cargar();
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<bool> toggleEstado(ServicioModel s) async {
    final nuevo = s.copyWithEstado(s.activo ? 'inactivo' : 'activo');
    return guardar(nuevo);
  }

  Future<bool> eliminar(int id) async {
    try {
      await _service.eliminar(id);
      await cargar();
      return true;
    } on ApiException {
      return false;
    }
  }
}

extension on ServicioModel {
  ServicioModel copyWithEstado(String estado) => ServicioModel(
        idServicio: idServicio,
        nombre: nombre,
        descripcion: descripcion,
        precio: precio,
        duracion: duracion,
        estado: estado,
      );
}
