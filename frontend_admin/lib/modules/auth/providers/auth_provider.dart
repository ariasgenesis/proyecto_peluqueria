import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/unauthorized_bridge.dart';
import '../../../core/storage/session_storage.dart';
import '../controllers/auth_controller.dart';
import '../models/usuario_model.dart';
import '../services/auth_service.dart';
import 'auth_state.dart';

export 'auth_state.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final controller = AuthController(
    authService: ref.watch(authServiceProvider),
    sessionStorage: ref.watch(sessionStorageProvider),
    bridge: ref.watch(unauthorizedBridgeProvider),
  );
  ref.onDispose(() => controller.disposeBridge());
  return controller;
});

final authStateProvider = authControllerProvider;

final currentUsuarioProvider = Provider<UsuarioModel?>((ref) {
  return ref.watch(authControllerProvider).usuario;
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUsuarioProvider)?.isAdmin ?? false;
});

final isEmpleadoProvider = Provider<bool>((ref) {
  return ref.watch(currentUsuarioProvider)?.isEmpleado ?? false;
});

final isStaffProvider = Provider<bool>((ref) {
  return ref.watch(currentUsuarioProvider)?.isStaff ?? false;
});

final isClienteProvider = Provider<bool>((ref) {
  return ref.watch(currentUsuarioProvider)?.isCliente ?? false;
});
