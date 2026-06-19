class CitaModel {
  const CitaModel({
    required this.idCita,
    required this.clienteId,
    required this.empleadoId,
    required this.fecha,
    required this.hora,
    required this.estado,
    this.clienteNombre,
    this.clienteApellido,
    this.empleadoNombre,
    this.empleadoApellido,
    this.serviciosResumen,
  });

  final int idCita;
  final int clienteId;
  final int empleadoId;
  final String fecha;
  final String hora;
  final String estado;
  final String? clienteNombre;
  final String? clienteApellido;
  final String? empleadoNombre;
  final String? empleadoApellido;
  final List<String>? serviciosResumen;

  factory CitaModel.fromJson(Map<String, dynamic> json) {
    return CitaModel(
      idCita: json['id_cita'] as int,
      clienteId: json['cliente_id'] as int,
      empleadoId: json['empleado_id'] as int,
      fecha: json['fecha'] as String,
      hora: json['hora'] as String,
      estado: json['estado'] as String,
      clienteNombre: json['cliente_nombre'] as String?,
      clienteApellido: json['cliente_apellido'] as String?,
      empleadoNombre: json['empleado_nombre'] as String?,
      empleadoApellido: json['empleado_apellido'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'cliente_id': clienteId,
        'empleado_id': empleadoId,
        'fecha': fecha,
        'hora': hora.length == 5 ? '$hora:00' : hora,
        'estado': estado,
      };

  CitaModel copyWith({String? estado}) => CitaModel(
        idCita: idCita,
        clienteId: clienteId,
        empleadoId: empleadoId,
        fecha: fecha,
        hora: hora,
        estado: estado ?? this.estado,
        clienteNombre: clienteNombre,
        clienteApellido: clienteApellido,
        empleadoNombre: empleadoNombre,
        empleadoApellido: empleadoApellido,
        serviciosResumen: serviciosResumen,
      );
}
