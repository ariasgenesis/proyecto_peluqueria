import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/dashboard_admin_model.dart';

class DashboardCitasList extends StatelessWidget {
  const DashboardCitasList({super.key, required this.citas});

  final List<CitaResumenModel> citas;

  @override
  Widget build(BuildContext context) {
    if (citas.isEmpty) {
      return const Text('No hay citas programadas para hoy');
    }

    return Column(
      children: citas.map((cita) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text('#${cita.idCita}'),
          ),
          title: Text('Cliente #${cita.clienteId} · ${Formatters.timeString(cita.hora)}'),
          subtitle: Text('Estilista #${cita.empleadoId}'),
          trailing: Chip(
            label: Text(cita.estado, style: const TextStyle(fontSize: 11)),
            visualDensity: VisualDensity.compact,
          ),
        );
      }).toList(),
    );
  }
}
