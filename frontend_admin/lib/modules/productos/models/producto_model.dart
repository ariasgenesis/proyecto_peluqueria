class ProductoModel {
  const ProductoModel({
    required this.idProducto,
    required this.nombre,
    required this.precio,
    required this.stock,
    required this.stockMinimo,
    required this.tipoControl,
    required this.estado,
  });

  final int idProducto;
  final String nombre;
  final double precio;
  final int stock;
  final int stockMinimo;
  final String tipoControl;
  final String estado;

  bool get activo => estado == 'activo';
  bool get stockBajo => stock <= stockMinimo;

  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    return ProductoModel(
      idProducto: json['id_producto'] as int,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      stock: json['stock'] as int,
      stockMinimo: json['stock_minimo'] as int,
      tipoControl: json['tipo_control'] as String? ?? 'manual',
      estado: json['estado'] as String? ?? 'activo',
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'precio': precio,
        'stock': stock,
        'stock_minimo': stockMinimo,
        'tipo_control': tipoControl,
        'estado': estado,
      };

  ProductoModel copyWithEstado(String e) => ProductoModel(
        idProducto: idProducto,
        nombre: nombre,
        precio: precio,
        stock: stock,
        stockMinimo: stockMinimo,
        tipoControl: tipoControl,
        estado: e,
      );
}
