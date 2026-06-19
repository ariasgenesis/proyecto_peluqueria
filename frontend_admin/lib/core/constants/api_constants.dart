import '../utils/api_config.dart';

/// Rutas y configuración REST del backend Flask.
class ApiConstants {
  ApiConstants._();

  static String get baseUrl => resolveApiBaseUrl();

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String login = '/usuarios/login';
  static const String dashboardAdmin = '/dashboard/admin';
  static const String dashboardEmpleado = '/dashboard/empleado';

  /// Colecciones Flask (blueprint termina en `/recurso/`).
  static const String empleados = '/empleados/';
  static const String clientes = '/clientes/';
  static const String horarios = '/horarios/';
  static const String servicios = '/servicios/';
  static const String productos = '/productos/';
  static const String citas = '/citas/';
  static const String detalleCitas = '/detalle_citas/';
  static const String facturas = '/facturas/';
  static const String pagos = '/pagos/';
  static const String movimientos = '/movimientos/';
  static const String reservasWeb = '/reservas_web/';

  static const String publicoServicios = '/publico/servicios';
  static const String publicoDisponibilidad = '/publico/disponibilidad';

  static String empleado(int id) => '/empleados/$id';
  static String cliente(int id) => '/clientes/$id';
  static String horario(int id) => '/horarios/$id';
  static String servicio(int id) => '/servicios/$id';
  static String producto(int id) => '/productos/$id';
  static String cita(int id) => '/citas/$id';
  static String factura(int id) => '/facturas/$id';
  static String pago(int id) => '/pagos/$id';
  static String reservaWeb(int id) => '/reservas_web/$id';

  static String productoAgregarStock(int id) => '/productos/$id/agregar-stock';
  static String productoDescontarStock(int id) =>
      '/productos/$id/descontar-stock';
  static String productoEditarStock(int id) => '/productos/$id/editar-stock';
  static const String productosStockBajo = '/productos/stock-bajo';
}
