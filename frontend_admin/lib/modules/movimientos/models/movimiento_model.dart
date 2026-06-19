class MovimientoModel {
  const MovimientoModel({
    required this.idMovimiento,
    required this.usuarioId,
    required this.tipo,
    required this.descripcion,
    required this.fecha,
  });

  final int idMovimiento;
  final int usuarioId;
  final String tipo;
  final String descripcion;
  final String fecha;

  factory MovimientoModel.fromJson(Map<String, dynamic> json) {
    return MovimientoModel(
      idMovimiento: json['id_movimiento'] as int,
      usuarioId: json['usuario_id'] as int,
      tipo: json['tipo'] as String,
      descripcion: json['descripcion'] as String,
      fecha: json['fecha'] as String,
    );
  }
}
