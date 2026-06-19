class ClienteModel {
  const ClienteModel({
    required this.idCliente,
    required this.nombre,
    required this.apellido,
    this.telefono,
    this.direccion,
  });

  final int idCliente;
  final String nombre;
  final String apellido;
  final String? telefono;
  final String? direccion;

  String get nombreCompleto => '$nombre $apellido'.trim();

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      idCliente: json['id_cliente'] as int,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      telefono: json['telefono'] as String?,
      direccion: json['direccion'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'apellido': apellido,
        if (telefono != null && telefono!.isNotEmpty) 'telefono': telefono,
        if (direccion != null && direccion!.isNotEmpty) 'direccion': direccion,
      };

  /// Payload mínimo para POST /clientes/ (sin id ni campos vacíos).
  Map<String, dynamic> toCreateJson() => {
        'nombre': nombre.trim(),
        'apellido': apellido.trim(),
        if (telefono != null && telefono!.trim().isNotEmpty) 'telefono': telefono!.trim(),
        if (direccion != null && direccion!.trim().isNotEmpty) 'direccion': direccion!.trim(),
      };
}
