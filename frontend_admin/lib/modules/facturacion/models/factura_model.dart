class FacturaModel {
  const FacturaModel({
    required this.idFactura,
    required this.citaId,
    required this.fecha,
    required this.total,
    required this.estado,
    this.generadaPor,
    this.modificadaPor,
    this.fechaModificacion,
    this.createdAt,
    this.updatedAt,
  });

  final int idFactura;
  final int citaId;
  final String fecha;
  final double total;
  final String estado;
  final int? generadaPor;
  final int? modificadaPor;
  final String? fechaModificacion;
  final String? createdAt;
  final String? updatedAt;

  bool get pagada => estado == 'pagada';

  factory FacturaModel.fromJson(Map<String, dynamic> json) {
    return FacturaModel(
      idFactura: json['id_factura'] as int,
      citaId: json['cita_id'] as int,
      fecha: json['fecha'] as String,
      total: (json['total'] as num).toDouble(),
      estado: json['estado'] as String? ?? 'pendiente',
      generadaPor: json['generada_por'] as int?,
      modificadaPor: json['modificada_por'] as int?,
      fechaModificacion: json['fecha_modificacion'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'cita_id': citaId,
    'fecha': fecha,
    'total': total,
    'estado': estado,
  };
}
