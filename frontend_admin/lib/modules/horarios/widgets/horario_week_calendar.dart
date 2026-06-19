import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../empleados/models/empleado_model.dart';
import '../models/horario_model.dart';

const _diasOrden = [
  'lunes',
  'martes',
  'miercoles',
  'jueves',
  'viernes',
  'sabado',
  'domingo',
];
const _diasLabel = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];

class HorarioWeekCalendar extends StatelessWidget {
  const HorarioWeekCalendar({
    super.key,
    required this.horarios,
    required this.empleados,
    this.readOnly = false,
    this.onBlockTap,
  });

  final List<HorarioModel> horarios;
  final Map<int, EmpleadoModel> empleados;
  final bool readOnly;
  final void Function(HorarioModel)? onBlockTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = constraints.maxWidth < 860
            ? 860.0
            : constraints.maxWidth;
        final employeeWidth = constraints.maxWidth < 860 ? 180.0 : 220.0;
        final dayWidth = (minWidth - employeeWidth) / 7;

        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: minWidth,
              child: Column(
                children: [
                  _WeekHeader(employeeWidth: employeeWidth, dayWidth: dayWidth),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      itemCount: empleados.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final emp = empleados.values.elementAt(index);
                        return _EmployeeRow(
                          empleado: emp,
                          horarios: horarios
                              .where((h) => h.empleadoId == emp.idEmpleado)
                              .toList(),
                          employeeWidth: employeeWidth,
                          dayWidth: dayWidth,
                          isDark: isDark,
                          readOnly: readOnly,
                          onBlockTap: onBlockTap,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.employeeWidth, required this.dayWidth});

  final double employeeWidth;
  final double dayWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          SizedBox(
            width: employeeWidth,
            child: Text(
              'Equipo',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          for (var i = 0; i < _diasOrden.length; i++)
            SizedBox(
              width: dayWidth,
              child: Center(
                child: Text(
                  _diasLabel[i],
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({
    required this.empleado,
    required this.horarios,
    required this.employeeWidth,
    required this.dayWidth,
    required this.isDark,
    required this.readOnly,
    this.onBlockTap,
  });

  final EmpleadoModel empleado;
  final List<HorarioModel> horarios;
  final double employeeWidth;
  final double dayWidth;
  final bool isDark;
  final bool readOnly;
  final void Function(HorarioModel)? onBlockTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: employeeWidth,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      empleado.nombreCompleto,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (empleado.cargo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        empleado.cargo!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            for (final dia in _diasOrden)
              _DayCell(
                width: dayWidth,
                horarios: horarios.where((h) => h.diaSemana == dia).toList(),
                readOnly: readOnly,
                onBlockTap: onBlockTap,
              ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.width,
    required this.horarios,
    required this.readOnly,
    this.onBlockTap,
  });

  final double width;
  final List<HorarioModel> horarios;
  final bool readOnly;
  final void Function(HorarioModel)? onBlockTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: horarios.isEmpty
          ? Center(
              child: Container(
                height: 34,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: horarios.map((h) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: readOnly ? null : () => onBlockTap?.call(h),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          '${Formatters.timeString(h.horaInicio)} - ${Formatters.timeString(h.horaFin)}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
