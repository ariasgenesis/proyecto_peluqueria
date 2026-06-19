class PagoModel {
  const PagoModel({
    required this.idPago,
    required this.facturaId,
    required this.metodo,
    required this.estado,
    required this.fecha,
    required this.monto,
  });

  final int idPago;
  final int facturaId;
  final String metodo;
  final String estado;
  final String fecha;
  final double monto;

  factory PagoModel.fromJson(Map<String, dynamic> json) {
    return PagoModel(
      idPago: json['id_pago'] as int,
      facturaId: json['factura_id'] as int,
      metodo: json['metodo'] as String,
      estado: json['estado'] as String? ?? 'completado',
      fecha: json['fecha'] as String,
      monto: (json['monto'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'factura_id': facturaId,
        'metodo': metodo,
        'estado': estado,
        'fecha': fecha,
        'monto': monto,
      };
}
