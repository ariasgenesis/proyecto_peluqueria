import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/cita_estados.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/lookup_provider.dart';
import '../models/cita_model.dart';

class CitaKanbanCard extends StatelessWidget {
  const CitaKanbanCard({
    super.key,
    required this.cita,
    required this.onTap,
    this.clientes,
    this.empleados,
  });

  final CitaModel cita;
  final VoidCallback onTap;
  final Map<int, dynamic>? clientes;
  final Map<int, dynamic>? empleados;

  @override
  Widget build(BuildContext context) {
    final color = CitaEstados.colorFor(cita.estado);
    final cliente = nombreCliente(
      null,
      cita.clienteId,
      nombre: cita.clienteNombre,
      apellido: cita.clienteApellido,
    );
    final empleado = nombreEmpleado(
      null,
      cita.empleadoId,
      nombre: cita.empleadoNombre,
      apellido: cita.empleadoApellido,
    );
    final retraso = _esRetraso(cita);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: retraso
                    ? AppColors.warning.withValues(alpha: 0.6)
                    : color.withValues(alpha: 0.20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.22
                        : 0.05,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cliente,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: (retraso ? AppColors.warning : color).withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        retraso ? Icons.schedule : Icons.arrow_forward_ios,
                        size: retraso ? 16 : 12,
                        color: retraso ? AppColors.warning : color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 15, color: color),
                    const SizedBox(width: 5),
                    Text(
                      Formatters.timeString(cita.hora),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: color,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        empleado,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    Chip(
                      label: Text(
                        CitaEstados.labelFor(cita.estado),
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: color.withValues(alpha: 0.12),
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                    ),
                    if (cita.serviciosResumen != null)
                      ...cita.serviciosResumen!
                          .take(2)
                          .map(
                            (s) => Chip(
                              label: Text(
                                s,
                                style: const TextStyle(fontSize: 10),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.03, end: 0);
  }

  bool _esRetraso(CitaModel c) {
    if (c.estado == 'cancelada' || c.estado == 'completada') return false;
    try {
      final now = DateTime.now();
      final parts = c.hora.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final citaMin = h * 60 + m;
      final nowMin = now.hour * 60 + now.minute;
      final hoy =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      return c.fecha == hoy && citaMin < nowMin;
    } catch (_) {
      return false;
    }
  }
}
