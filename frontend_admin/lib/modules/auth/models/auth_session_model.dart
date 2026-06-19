import 'usuario_model.dart';

class AuthSessionModel {
  const AuthSessionModel({
    required this.accessToken,
    required this.usuario,
  });

  final String accessToken;
  final UsuarioModel usuario;

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      accessToken: json['access_token'] as String,
      usuario: UsuarioModel.fromJson(
        json['usuario'] as Map<String, dynamic>,
      ),
    );
  }
}
