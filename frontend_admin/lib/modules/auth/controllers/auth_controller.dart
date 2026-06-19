import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/network/unauthorized_bridge.dart';
import '../../../core/storage/session_storage.dart';
import '../providers/auth_state.dart';
import '../services/auth_service.dart';
import '../utils/auth_token_utils.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthService authService,
    required SessionStorage sessionStorage,
    required UnauthorizedBridge bridge,
  })  : _authService = authService,
        _sessionStorage = sessionStorage,
        _bridge = bridge,
        super(const AuthState(status: AuthStatus.loading)) {
    _bridge.onUnauthorized = _handleUnauthorized;
    _restoreSession();
  }

  final AuthService _authService;
  final SessionStorage _sessionStorage;
  final UnauthorizedBridge _bridge;

  void disposeBridge() {
    _bridge.onUnauthorized = null;
  }

  Future<void> _restoreSession() async {
    final usuario = _sessionStorage.getUsuario();
    final token = _sessionStorage.getToken();
    if (usuario != null && isTokenValid(token)) {
      if (!usuario.isStaff) {
        await _sessionStorage.clearSession();
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      state = AuthState(
        status: AuthStatus.authenticated,
        usuario: usuario,
        token: token,
      );
    } else {
      await _sessionStorage.clearSession();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
    );

    try {
      final session = await _authService.login(
        username: username,
        password: password,
      );
      if (!session.usuario.isStaff) {
        state = const AuthState(
          status: AuthStatus.error,
          errorMessage:
              'Acceso denegado. Este portal es solo para personal autorizado.',
        );
        return false;
      }
      await _sessionStorage.saveSession(
        token: session.accessToken,
        usuario: session.usuario,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        usuario: session.usuario,
        token: session.accessToken,
      );
      return true;
    } on ApiException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'No se pudo iniciar sesión',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _sessionStorage.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void _handleUnauthorized() {
    logout();
  }
}
