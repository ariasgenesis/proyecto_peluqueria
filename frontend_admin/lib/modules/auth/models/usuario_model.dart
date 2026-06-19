class UsuarioModel {
  const UsuarioModel({
    required this.idUsuario,
    required this.username,
    this.email,
    required this.rol,
    required this.estado,
  });

  final int idUsuario;
  final String username;
  final String? email;
  final String rol;
  final String estado;

  bool get isAdmin => rol == 'admin';
  bool get isEmpleado => rol == 'empleado';
  bool get isCliente => rol == 'cliente';
  bool get isStaff => isAdmin || isEmpleado;

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      idUsuario: json['id_usuario'] as int,
      username: json['username'] as String,
      email: json['email'] as String?,
      rol: json['rol'] as String,
      estado: json['estado'] as String? ?? 'activo',
    );
  }

  Map<String, dynamic> toJson() => {
        'id_usuario': idUsuario,
        'username': username,
        'email': email,
        'rol': rol,
        'estado': estado,
      };
}
