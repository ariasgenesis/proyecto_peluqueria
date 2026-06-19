import '../models/usuario_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.usuario,
    this.token,
    this.errorMessage,
  });

  final AuthStatus status;
  final UsuarioModel? usuario;
  final String? token;
  final String? errorMessage;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated &&
      token != null &&
      token!.isNotEmpty &&
      usuario != null;

  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UsuarioModel? usuario,
    String? token,
    String? errorMessage,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      usuario: clearSession ? null : (usuario ?? this.usuario),
      token: clearSession ? null : (token ?? this.token),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
