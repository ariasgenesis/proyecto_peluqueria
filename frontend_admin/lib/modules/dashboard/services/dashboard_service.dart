import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_admin_model.dart';
import '../models/dashboard_empleado_model.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(ref.watch(apiClientProvider));
});

class DashboardService {
  DashboardService(this._client);

  final ApiClient _client;

  Future<DashboardAdminModel> fetchAdmin() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.dashboardAdmin,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return DashboardAdminModel.fromJson(response.data!);
  }

  Future<DashboardEmpleadoModel> fetchEmpleado() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.dashboardEmpleado,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return DashboardEmpleadoModel.fromJson(response.data!);
  }
}
