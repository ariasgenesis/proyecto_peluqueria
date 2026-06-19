class EmpleadoModel {
  const EmpleadoModel({
    required this.idEmpleado,
    this.usuarioId = 0,
    required this.nombre,
    required this.apellido,
    this.documento,
    this.telefono,
    this.cargo,
    this.rol = 'empleado',
  });

  final int idEmpleado;
  final int usuarioId;
  final String nombre;
  final String apellido;
  final String? documento;
  final String? telefono;
  final String? cargo;
  final String rol;

  String get nombreCompleto => '$nombre $apellido'.trim();

  factory EmpleadoModel.fromJson(Map<String, dynamic> json) {
    return EmpleadoModel(
      idEmpleado: json['id_empleado'] as int,
      usuarioId: json['usuario_id'] as int? ?? 0,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      documento: json['documento'] as String?,
      telefono: json['telefono'] as String?,
      cargo: json['cargo'] as String?,
      rol: json['rol'] as String? ?? 'empleado',
    );
  }

  Map<String, dynamic> toJson({bool includePin = false, String? pin}) {
    final map = <String, dynamic>{
      'nombre': nombre,
      'apellido': apellido,
      if (documento != null && documento!.isNotEmpty) 'documento': documento,
      'telefono': telefono,
      'cargo': cargo,
      'rol': rol,
    };
    if (includePin && pin != null) map['pin'] = pin;
    return map;
  }
}
