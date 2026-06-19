class HorarioModel {
  const HorarioModel({
    required this.idHorario,
    required this.empleadoId,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
  });

  final int idHorario;
  final int empleadoId;
  final String diaSemana;
  final String horaInicio;
  final String horaFin;

  factory HorarioModel.fromJson(Map<String, dynamic> json) {
    return HorarioModel(
      idHorario: json['id_horario'] as int,
      empleadoId: json['empleado_id'] as int,
      diaSemana: json['dia_semana'] as String,
      horaInicio: json['hora_inicio'] as String,
      horaFin: json['hora_fin'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'empleado_id': empleadoId,
        'dia_semana': diaSemana,
        'hora_inicio': horaInicio.length == 5 ? '$horaInicio:00' : horaInicio,
        'hora_fin': horaFin.length == 5 ? '$horaFin:00' : horaFin,
      };
}
