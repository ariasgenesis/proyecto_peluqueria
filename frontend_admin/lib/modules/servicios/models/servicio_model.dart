class ServicioModel {
  const ServicioModel({
    required this.idServicio,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.duracion,
    required this.estado,
  });

  final int idServicio;
  final String nombre;
  final String? descripcion;
  final double precio;
  final int duracion;
  final String estado;

  bool get activo => estado == 'activo';

  factory ServicioModel.fromJson(Map<String, dynamic> json) {
    return ServicioModel(
      idServicio: json['id_servicio'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      precio: (json['precio'] as num).toDouble(),
      duracion: json['duracion'] as int,
      estado: json['estado'] as String? ?? 'activo',
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'duracion': duracion,
        'estado': estado,
      };
}
