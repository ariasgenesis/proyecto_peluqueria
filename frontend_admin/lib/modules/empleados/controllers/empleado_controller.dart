import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../models/empleado_model.dart';
import '../services/empleado_service.dart';

class EmpleadoListState {
  const EmpleadoListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.page = 1,
    this.total = 0,
  });

  final List<EmpleadoModel> items;
  final bool isLoading;
  final String? error;
  final String search;
  final int page;
  final int total;

  EmpleadoListState copyWith({
    List<EmpleadoModel>? items,
    bool? isLoading,
    String? error,
    String? search,
    int? page,
    int? total,
    bool clearError = false,
  }) {
    return EmpleadoListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

final empleadoListControllerProvider =
    StateNotifierProvider<EmpleadoListController, EmpleadoListState>((ref) {
  return EmpleadoListController(ref.watch(empleadoServiceProvider));
});

class EmpleadoListController extends StateNotifier<EmpleadoListState> {
  EmpleadoListController(this._service) : super(const EmpleadoListState()) {
    cargar();
  }

  final EmpleadoService _service;

  Future<void> cargar({String? search}) async {
    state = state.copyWith(
      isLoading: true,
      search: search ?? state.search,
      clearError: true,
    );
    try {
      final res = await _service.listar(search: state.search.isEmpty ? null : state.search);
      state = state.copyWith(
        items: res.data,
        isLoading: false,
        total: res.total,
        page: res.page,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<bool> guardar(EmpleadoModel empleado, {String? pin, bool esNuevo = false}) async {
    try {
      final hasPin = pin != null && pin.isNotEmpty;
      final payload = empleado.toJson(includePin: esNuevo || hasPin, pin: pin);
      if (esNuevo) {
        await _service.crear(payload);
      } else {
        if (hasPin) payload['pin'] = pin;
        await _service.actualizar(empleado.idEmpleado, payload);
      }
      await cargar();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<bool> eliminar(int id) async {
    try {
      await _service.eliminar(id);
      await cargar();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }
}
