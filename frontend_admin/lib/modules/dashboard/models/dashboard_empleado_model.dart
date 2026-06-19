class CitaEmpleadoModel {
  const CitaEmpleadoModel({
    required this.idCita,
    required this.clienteId,
    required this.fecha,
    required this.hora,
    required this.estado,
    this.clienteNombre,
    this.clienteApellido,
  });

  final int idCita;
  final int clienteId;
  final String fecha;
  final String hora;
  final String estado;
  final String? clienteNombre;
  final String? clienteApellido;

  String get clienteDisplay {
    if (clienteNombre != null && clienteNombre!.isNotEmpty) {
      return '$clienteNombre ${clienteApellido ?? ''}'.trim();
    }
    return 'Cliente #$clienteId';
  }

  factory CitaEmpleadoModel.fromJson(Map<String, dynamic> json) {
    return CitaEmpleadoModel(
      idCita: json['id_cita'] as int,
      clienteId: json['cliente_id'] as int,
      fecha: json['fecha'] as String,
      hora: json['hora'] as String,
      estado: json['estado'] as String,
      clienteNombre: json['cliente_nombre'] as String?,
      clienteApellido: json['cliente_apellido'] as String?,
    );
  }
}

class ActividadRecienteModel {
  const ActividadRecienteModel({
    required this.idMovimiento,
    required this.tipo,
    required this.descripcion,
    required this.fecha,
  });

  final int idMovimiento;
  final String tipo;
  final String descripcion;
  final String fecha;

  factory ActividadRecienteModel.fromJson(Map<String, dynamic> json) {
    return ActividadRecienteModel(
      idMovimiento: json['id_movimiento'] as int,
      tipo: json['tipo'] as String,
      descripcion: json['descripcion'] as String,
      fecha: json['fecha'] as String,
    );
  }
}

class DashboardEmpleadoModel {
  const DashboardEmpleadoModel({
    required this.citasDia,
    required this.proximasCitas,
    required this.actividadReciente,
  });

  final List<CitaEmpleadoModel> citasDia;
  final List<CitaEmpleadoModel> proximasCitas;
  final List<ActividadRecienteModel> actividadReciente;

  factory DashboardEmpleadoModel.fromJson(Map<String, dynamic> json) {
    List<CitaEmpleadoModel> parse(String key) {
      return (json[key] as List<dynamic>? ?? [])
          .map((e) => CitaEmpleadoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return DashboardEmpleadoModel(
      citasDia: parse('citas_dia'),
      proximasCitas: parse('proximas_citas'),
      actividadReciente: (json['actividad_reciente'] as List<dynamic>? ?? [])
          .map((e) => ActividadRecienteModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
