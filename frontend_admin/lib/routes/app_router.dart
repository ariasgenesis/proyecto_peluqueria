import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../modules/auth/pages/access_denied_page.dart';
import '../modules/auth/pages/login_page.dart';
import '../modules/auth/providers/auth_provider.dart';
import '../modules/auth/utils/auth_token_utils.dart';
import '../modules/citas/pages/cita_kanban_page.dart';
import '../modules/clientes/pages/cliente_list_page.dart';
import '../modules/dashboard/pages/admin_dashboard_page.dart';
import '../modules/dashboard/pages/empleado_dashboard_page.dart';
import '../modules/empleados/pages/empleado_list_page.dart';
import '../modules/facturacion/pages/factura_list_page.dart';
import '../modules/horarios/pages/horario_calendar_page.dart';
import '../modules/inventario/pages/inventario_page.dart';
import '../modules/movimientos/pages/movimiento_list_page.dart';
import '../modules/pagos/pages/pago_list_page.dart';
import '../modules/productos/pages/producto_list_page.dart';
import '../modules/servicios/pages/servicio_list_page.dart';
import '../modules/sitio_publico/pages/sitio_contacto_page.dart';
import '../modules/sitio_publico/pages/sitio_home_page.dart';
import '../modules/sitio_publico/pages/sitio_servicios_page.dart';
import 'route_names.dart';

final _routerRefreshProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => notifier.value++);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final refresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: RouteNames.login,
    refreshListenable: refresh,
    redirect: (context, state) {
      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        return null;
      }

      final isAuthenticated = authState.isAuthenticated &&
          isTokenValid(authState.token);
      final location = state.matchedLocation;
      final isLogin = location == RouteNames.login;
      final isSitioPublico = location.startsWith(RouteNames.sitioInicio);

      if (location == '/kanban') {
        return RouteNames.citas;
      }

      if (!isAuthenticated && !isLogin && !isSitioPublico) {
        return RouteNames.login;
      }

      if (isAuthenticated && isLogin) {
        final usuario = authState.usuario;
        if (!(usuario?.isStaff ?? false)) {
          return RouteNames.accesoDenegado;
        }
        if (usuario?.isAdmin ?? false) {
          return RouteNames.dashboardAdmin;
        }
        return RouteNames.dashboardEmpleado;
      }

      if (isAuthenticated) {
        final usuario = authState.usuario;
        if (!(usuario?.isStaff ?? false)) {
          if (location != RouteNames.accesoDenegado) {
            return RouteNames.accesoDenegado;
          }
          return null;
        }
        if (usuario?.isEmpleado ?? false) {
          if (!_empleadoAllowedRoutes.contains(location)) {
            return RouteNames.dashboardEmpleado;
          }
        }
        if (!(usuario?.isAdmin ?? false) && _adminOnlyRoutes.contains(location)) {
          return RouteNames.dashboardEmpleado;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.login,
        pageBuilder: (_, _) => const NoTransitionPage(child: LoginPage()),
      ),
      GoRoute(
        path: RouteNames.accesoDenegado,
        pageBuilder: (_, _) => const NoTransitionPage(child: AccessDeniedPage()),
      ),
      GoRoute(
        path: RouteNames.dashboardAdmin,
        pageBuilder: (_, _) => const NoTransitionPage(child: AdminDashboardPage()),
      ),
      GoRoute(
        path: RouteNames.dashboardEmpleado,
        pageBuilder: (_, _) => const NoTransitionPage(child: EmpleadoDashboardPage()),
      ),
      GoRoute(
        path: RouteNames.empleados,
        pageBuilder: (_, _) => const NoTransitionPage(child: EmpleadoListPage()),
      ),
      GoRoute(
        path: RouteNames.clientes,
        pageBuilder: (_, _) => const NoTransitionPage(child: ClienteListPage()),
      ),
      GoRoute(
        path: RouteNames.horarios,
        pageBuilder: (_, _) => const NoTransitionPage(child: HorarioCalendarPage()),
      ),
      GoRoute(
        path: RouteNames.servicios,
        pageBuilder: (_, _) => const NoTransitionPage(child: ServicioListPage()),
      ),
      GoRoute(
        path: RouteNames.citas,
        pageBuilder: (_, _) => const NoTransitionPage(child: CitaKanbanPage()),
      ),
      GoRoute(
        path: RouteNames.productos,
        pageBuilder: (_, _) => const NoTransitionPage(child: ProductoListPage()),
      ),
      GoRoute(
        path: RouteNames.inventario,
        pageBuilder: (_, _) => const NoTransitionPage(child: InventarioPage()),
      ),
      GoRoute(
        path: RouteNames.facturacion,
        pageBuilder: (_, _) => const NoTransitionPage(child: FacturaListPage()),
      ),
      GoRoute(
        path: RouteNames.pagos,
        pageBuilder: (_, _) => const NoTransitionPage(child: PagoListPage()),
      ),
      GoRoute(
        path: RouteNames.movimientos,
        pageBuilder: (_, _) => const NoTransitionPage(child: MovimientoListPage()),
      ),
      GoRoute(
        path: RouteNames.sitioInicio,
        pageBuilder: (_, _) => const NoTransitionPage(child: SitioHomePage()),
        routes: [
          GoRoute(
            path: 'servicios',
            pageBuilder: (_, _) => const NoTransitionPage(child: SitioServiciosPage()),
          ),
          GoRoute(
            path: 'contacto',
            pageBuilder: (_, _) => const NoTransitionPage(child: SitioContactoPage()),
          ),
        ],
      ),
      GoRoute(path: '/', redirect: (_, _) => RouteNames.login),
      GoRoute(path: '/kanban', redirect: (_, _) => RouteNames.citas),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
    ),
  );
});

const _adminOnlyRoutes = {
  RouteNames.dashboardAdmin,
  RouteNames.empleados,
  RouteNames.clientes,
  RouteNames.servicios,
  RouteNames.productos,
  RouteNames.inventario,
  RouteNames.facturacion,
  RouteNames.pagos,
  RouteNames.movimientos,
};

const _empleadoAllowedRoutes = {
  RouteNames.dashboardEmpleado,
  RouteNames.citas,
  RouteNames.horarios,
};
