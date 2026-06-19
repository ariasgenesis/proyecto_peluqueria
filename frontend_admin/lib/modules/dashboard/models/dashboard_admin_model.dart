class DashboardMetricasModel {
  const DashboardMetricasModel({
    required this.citasHoy,
    required this.citasPendientes,
    required this.ingresosHoy,
    required this.clientesTotal,
    required this.serviciosActivos,
    required this.stockBajo,
  });

  final int citasHoy;
  final int citasPendientes;
  final double ingresosHoy;
  final int clientesTotal;
  final int serviciosActivos;
  final int stockBajo;

  factory DashboardMetricasModel.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    return DashboardMetricasModel(
      citasHoy: data['citas_hoy'] as int? ?? 0,
      citasPendientes: data['citas_pendientes'] as int? ?? 0,
      ingresosHoy: (data['ingresos_hoy'] as num? ?? 0).toDouble(),
      clientesTotal: data['clientes_total'] as int? ?? 0,
      serviciosActivos: data['servicios_activos'] as int? ?? 0,
      stockBajo: data['stock_bajo'] as int? ?? 0,
    );
  }
}

class DashboardChartPoint {
  const DashboardChartPoint({required this.label, required this.value});

  final String label;
  final double value;

  factory DashboardChartPoint.fromJson(
    Map<String, dynamic> json,
    String labelKey,
    String valueKey,
  ) {
    return DashboardChartPoint(
      label: json[labelKey].toString(),
      value: (json[valueKey] as num? ?? 0).toDouble(),
    );
  }
}

class CitaResumenModel {
  const CitaResumenModel({
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

  String get clienteDisplay {
    if (clienteNombre != null && clienteNombre!.isNotEmpty) {
      return '$clienteNombre ${clienteApellido ?? ''}'.trim();
    }
    return 'Cliente #$clienteId';
  }

  String get empleadoDisplay {
    if (empleadoNombre != null && empleadoNombre!.isNotEmpty) {
      return '$empleadoNombre ${empleadoApellido ?? ''}'.trim();
    }
    return 'Empleado #$empleadoId';
  }

  factory CitaResumenModel.fromJson(Map<String, dynamic> json) {
    return CitaResumenModel(
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
}

class FacturaResumenModel {
  const FacturaResumenModel({
    required this.idFactura,
    required this.citaId,
    required this.fecha,
    required this.total,
    required this.estado,
  });

  final int idFactura;
  final int? citaId;
  final String fecha;
  final double total;
  final String estado;

  factory FacturaResumenModel.fromJson(Map<String, dynamic> json) {
    return FacturaResumenModel(
      idFactura: json['id_factura'] as int,
      citaId: json['cita_id'] as int?,
      fecha: json['fecha'] as String,
      total: (json['total'] as num).toDouble(),
      estado: json['estado'] as String,
    );
  }
}

class ProductoStockBajoModel {
  const ProductoStockBajoModel({
    required this.idProducto,
    required this.nombre,
    required this.stock,
    required this.stockMinimo,
  });

  final int idProducto;
  final String nombre;
  final int stock;
  final int stockMinimo;

  factory ProductoStockBajoModel.fromJson(Map<String, dynamic> json) {
    return ProductoStockBajoModel(
      idProducto: json['id_producto'] as int,
      nombre: json['nombre'] as String,
      stock: json['stock'] as int,
      stockMinimo: json['stock_minimo'] as int,
    );
  }
}

class MovimientoResumenModel {
  const MovimientoResumenModel({
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

  factory MovimientoResumenModel.fromJson(Map<String, dynamic> json) {
    return MovimientoResumenModel(
      idMovimiento: json['id_movimiento'] as int,
      usuarioId: json['usuario_id'] as int,
      tipo: json['tipo'] as String,
      descripcion: json['descripcion'] as String,
      fecha: json['fecha'] as String,
    );
  }
}

class DashboardAdminModel {
  const DashboardAdminModel({
    required this.metricas,
    required this.citasPorEstado,
    required this.ingresosSemana,
    required this.citasHoy,
    required this.facturasRecientes,
    required this.productosStockBajo,
    required this.movimientosRecientes,
  });

  final DashboardMetricasModel metricas;
  final List<DashboardChartPoint> citasPorEstado;
  final List<DashboardChartPoint> ingresosSemana;
  final List<CitaResumenModel> citasHoy;
  final List<FacturaResumenModel> facturasRecientes;
  final List<ProductoStockBajoModel> productosStockBajo;
  final List<MovimientoResumenModel> movimientosRecientes;

  factory DashboardAdminModel.fromJson(Map<String, dynamic> json) {
    return DashboardAdminModel(
      metricas: DashboardMetricasModel.fromJson(
        json['metricas'] as Map<String, dynamic>?,
      ),
      citasPorEstado: (json['citas_por_estado'] as List<dynamic>? ?? [])
          .map(
            (e) => DashboardChartPoint.fromJson(
              e as Map<String, dynamic>,
              'estado',
              'total',
            ),
          )
          .toList(),
      ingresosSemana: (json['ingresos_semana'] as List<dynamic>? ?? [])
          .map(
            (e) => DashboardChartPoint.fromJson(
              e as Map<String, dynamic>,
              'fecha',
              'total',
            ),
          )
          .toList(),
      citasHoy: (json['citas_hoy'] as List<dynamic>? ?? [])
          .map((e) => CitaResumenModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      facturasRecientes: (json['facturas_recientes'] as List<dynamic>? ?? [])
          .map((e) => FacturaResumenModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      productosStockBajo: (json['productos_stock_bajo'] as List<dynamic>? ?? [])
          .map(
            (e) => ProductoStockBajoModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      movimientosRecientes:
          (json['movimientos_recientes'] as List<dynamic>? ?? [])
              .map(
                (e) =>
                    MovimientoResumenModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}
