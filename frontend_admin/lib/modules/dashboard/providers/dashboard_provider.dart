import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/dashboard_controller.dart';
import '../models/dashboard_admin_model.dart';
import '../models/dashboard_empleado_model.dart';

final dashboardAdminProvider =
    AsyncNotifierProvider<DashboardAdminNotifier, DashboardAdminModel>(
  DashboardAdminNotifier.new,
);

final dashboardEmpleadoProvider =
    AsyncNotifierProvider<DashboardEmpleadoNotifier, DashboardEmpleadoModel>(
  DashboardEmpleadoNotifier.new,
);
