import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../models/cliente_model.dart';
import '../services/cliente_service.dart';

class ClienteListState {
  const ClienteListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
  });

  final List<ClienteModel> items;
  final bool isLoading;
  final String? error;
  final String search;

  ClienteListState copyWith({
    List<ClienteModel>? items,
    bool? isLoading,
    String? error,
    String? search,
    bool clearError = false,
  }) =>
      ClienteListState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        search: search ?? this.search,
      );
}

final clienteListControllerProvider =
    StateNotifierProvider<ClienteListController, ClienteListState>((ref) {
  return ClienteListController(ref.watch(clienteServiceProvider));
});

class ClienteListController extends StateNotifier<ClienteListState> {
  ClienteListController(this._service) : super(const ClienteListState()) {
    cargar();
  }

  final ClienteService _service;

  Future<void> cargar({String? search}) async {
    state = state.copyWith(isLoading: true, search: search ?? state.search, clearError: true);
    try {
      final res = await _service.listar(search: state.search.isEmpty ? null : state.search);
      state = state.copyWith(items: res.data, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<bool> guardar(ClienteModel c, {bool esNuevo = false}) async {
    try {
      if (esNuevo) {
        await _service.crear(c.toCreateJson());
      } else {
        await _service.actualizar(c.idCliente, c.toJson());
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
