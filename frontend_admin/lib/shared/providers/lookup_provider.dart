import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/clientes/models/cliente_model.dart';
import '../../modules/clientes/services/cliente_service.dart';
import '../../modules/empleados/models/empleado_model.dart';
import '../../modules/empleados/services/empleado_service.dart';

final clientesLookupProvider = FutureProvider<Map<int, ClienteModel>>((ref) async {
  final service = ref.watch(clienteServiceProvider);
  final page = await service.listar(page: 1, perPage: 100);
  return {for (final c in page.data) c.idCliente: c};
});

final empleadosLookupProvider = FutureProvider<Map<int, EmpleadoModel>>((ref) async {
  final service = ref.watch(empleadoServiceProvider);
  final page = await service.listar(page: 1, perPage: 100);
  return {for (final e in page.data) e.idEmpleado: e};
});

String nombreCliente(Map<int, ClienteModel>? map, int id, {String? nombre, String? apellido}) {
  if (nombre != null && nombre.isNotEmpty) {
    return '$nombre ${apellido ?? ''}'.trim();
  }
  final c = map?[id];
  if (c == null) return 'Cliente #$id';
  return c.nombreCompleto;
}

String nombreEmpleado(Map<int, EmpleadoModel>? map, int id, {String? nombre, String? apellido}) {
  if (nombre != null && nombre.isNotEmpty) {
    return '$nombre ${apellido ?? ''}'.trim();
  }
  final e = map?[id];
  if (e == null) return 'Empleado #$id';
  return e.nombreCompleto;
}
