import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../models/dashboard_admin_model.dart';
import '../models/dashboard_empleado_model.dart';
import '../services/dashboard_service.dart';

class DashboardAdminNotifier extends AsyncNotifier<DashboardAdminModel> {
  @override
  Future<DashboardAdminModel> build() => _load();

  Future<DashboardAdminModel> _load() async {
    final service = ref.read(dashboardServiceProvider);
    try {
      return await service.fetchAdmin();
    } on ApiException catch (e) {
      throw e.message;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

class DashboardEmpleadoNotifier extends AsyncNotifier<DashboardEmpleadoModel> {
  @override
  Future<DashboardEmpleadoModel> build() => _load();

  Future<DashboardEmpleadoModel> _load() async {
    final service = ref.read(dashboardServiceProvider);
    try {
      return await service.fetchEmpleado();
    } on ApiException catch (e) {
      throw e.message;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}
