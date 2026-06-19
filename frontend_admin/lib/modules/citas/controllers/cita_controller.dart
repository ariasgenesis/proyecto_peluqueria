import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/cita_estados.dart';
import '../../../core/errors/api_exception.dart';
import '../models/cita_model.dart';
import '../services/cita_service.dart';

class CitaBoardState {
  const CitaBoardState({
    this.citas = const [],
    this.isLoading = false,
    this.error,
  });

  final List<CitaModel> citas;
  final bool isLoading;
  final String? error;

  Map<String, List<CitaModel>> get porColumna {
    final map = <String, List<CitaModel>>{
      for (final col in CitaEstados.kanbanColumns) col.id: [],
    };
    for (final c in citas) {
      map.putIfAbsent(c.estado, () => []).add(c);
    }
    return map;
  }
}

final citaBoardControllerProvider =
    StateNotifierProvider<CitaBoardController, CitaBoardState>((ref) {
  return CitaBoardController(ref.watch(citaServiceProvider));
});

class CitaBoardController extends StateNotifier<CitaBoardState> {
  CitaBoardController(this._service) : super(const CitaBoardState()) {
    cargar();
  }

  final CitaService _service;

  Future<void> cargar() async {
    state = const CitaBoardState(isLoading: true);
    try {
      final res = await _service.listar(perPage: 100);
      state = CitaBoardState(citas: res.data);
    } on ApiException catch (e) {
      state = CitaBoardState(error: e.message);
    }
  }

  Future<bool> moverEstado(CitaModel cita, String nuevoEstado) async {
    if (cita.estado == nuevoEstado) return true;
    try {
      await _service.actualizar(cita.idCita, {'estado': nuevoEstado});
      final updated = state.citas.map((c) {
        if (c.idCita == cita.idCita) return c.copyWith(estado: nuevoEstado);
        return c;
      }).toList();
      state = CitaBoardState(citas: updated);
      return true;
    } on ApiException catch (e) {
      state = CitaBoardState(citas: state.citas, error: e.message);
      return false;
    }
  }

  Future<bool> guardar(CitaModel cita, {bool esNuevo = false}) async {
    try {
      if (esNuevo) {
        await _service.crear(cita.toJson());
      } else {
        await _service.actualizar(cita.idCita, cita.toJson());
      }
      await cargar();
      return true;
    } on ApiException catch (e) {
      state = CitaBoardState(citas: state.citas, error: e.message);
      return false;
    }
  }

  Future<bool> cancelar(int id) => moverEstado(
        state.citas.firstWhere((c) => c.idCita == id),
        'cancelada',
      );
}
