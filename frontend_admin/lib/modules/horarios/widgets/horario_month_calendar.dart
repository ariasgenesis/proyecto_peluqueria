import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/cita_estados.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../routes/route_names.dart';
import '../../../shared/dialogs/app_modal_sheet.dart';
import '../../citas/models/cita_model.dart';
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

const _diasCorto = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
const _meses = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

class HorarioMonthCalendar extends StatelessWidget {
  const HorarioMonthCalendar({
    super.key,
    required this.horarios,
    required this.citas,
    required this.empleados,
    required this.visibleMonth,
    required this.selectedDate,
    required this.selectedEmpleadoId,
    required this.selectedEstado,
    required this.searchText,
    required this.readOnly,
    required this.onMonthChanged,
    required this.onSelectedDateChanged,
    required this.onEmpleadoFilterChanged,
    required this.onEstadoFilterChanged,
    required this.onSearchChanged,
    required this.onHorarioTap,
    required this.onCitaEdit,
    required this.onCitaStatusChange,
    this.onNewHorario,
    this.onNewCita,
    this.onRefresh,
  });

  final List<HorarioModel> horarios;
  final List<CitaModel> citas;
  final Map<int, EmpleadoModel> empleados;
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final int? selectedEmpleadoId;
  final String? selectedEstado;
  final String searchText;
  final bool readOnly;
  final void Function(DateTime) onMonthChanged;
  final void Function(DateTime) onSelectedDateChanged;
  final void Function(int?) onEmpleadoFilterChanged;
  final void Function(String?) onEstadoFilterChanged;
  final void Function(String) onSearchChanged;
  final void Function(HorarioModel) onHorarioTap;
  final void Function(CitaModel) onCitaEdit;
  final Future<bool> Function(CitaModel, String) onCitaStatusChange;
  final VoidCallback? onNewHorario;
  final VoidCallback? onNewCita;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final filteredCitas = _filteredCitas();
    final selectedCitas = _citasForDate(filteredCitas, selectedDate);
    final selectedHorarios = _horariosForDate(selectedDate);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 24,
        8,
        isMobile ? 12 : 24,
        18,
      ),
      child: Column(
        children: [
          _CalendarToolbar(
            visibleMonth: visibleMonth,
            empleados: empleados,
            selectedEmpleadoId: selectedEmpleadoId,
            selectedEstado: selectedEstado,
            searchText: searchText,
            readOnly: readOnly,
            onMonthChanged: onMonthChanged,
            onEmpleadoFilterChanged: onEmpleadoFilterChanged,
            onEstadoFilterChanged: onEstadoFilterChanged,
            onSearchChanged: onSearchChanged,
            onNewHorario: onNewHorario,
            onNewCita: onNewCita,
            onRefresh: onRefresh,
          ),
          const SizedBox(height: 14),
          Expanded(
            child: isMobile
                ? _MobileAgenda(
                    visibleMonth: visibleMonth,
                    selectedDate: selectedDate,
                    citas: filteredCitas,
                    horariosForDate: _horariosForDate,
                    empleados: empleados,
                    onSelectedDateChanged: onSelectedDateChanged,
                    onOpenDay: (date) => _openDayModal(
                      context,
                      date,
                      _citasForDate(filteredCitas, date),
                      _horariosForDate(date),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CalendarSidePanel(
                        selectedDate: selectedDate,
                        citas: selectedCitas,
                        horarios: selectedHorarios,
                        empleados: empleados,
                        onOpenDay: () => _openDayModal(
                          context,
                          selectedDate,
                          selectedCitas,
                          selectedHorarios,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _MonthGrid(
                          visibleMonth: visibleMonth,
                          selectedDate: selectedDate,
                          citas: filteredCitas,
                          horariosForDate: _horariosForDate,
                          empleados: empleados,
                          onSelectedDateChanged: onSelectedDateChanged,
                          onOpenDay: (date) => _openDayModal(
                            context,
                            date,
                            _citasForDate(filteredCitas, date),
                            _horariosForDate(date),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<CitaModel> _filteredCitas() {
    final query = searchText.trim().toLowerCase();
    return citas.where((cita) {
      if (selectedEmpleadoId != null && cita.empleadoId != selectedEmpleadoId) {
        return false;
      }
      if (selectedEstado != null) {
        final visualEstado = _visualEstado(cita);
        if (selectedEstado == 'retrasada') {
          if (visualEstado != 'retrasada') return false;
        } else if (cita.estado != selectedEstado) {
          return false;
        }
      }
      if (query.isEmpty) return true;
      final empleado = empleados[cita.empleadoId]?.nombreCompleto ?? '';
      final cliente =
          '${cita.clienteNombre ?? ''} ${cita.clienteApellido ?? ''}';
      return empleado.toLowerCase().contains(query) ||
          cliente.toLowerCase().contains(query) ||
          cita.idCita.toString().contains(query);
    }).toList();
  }

  List<CitaModel> _citasForDate(List<CitaModel> source, DateTime date) {
    final iso = _isoDate(date);
    final list = source.where((cita) => cita.fecha == iso).toList();
    list.sort((a, b) => a.hora.compareTo(b.hora));
    return list;
  }

  List<HorarioModel> _horariosForDate(DateTime date) {
    final dia = _diasOrden[date.weekday - 1];
    return horarios.where((h) {
      if (selectedEmpleadoId != null && h.empleadoId != selectedEmpleadoId) {
        return false;
      }
      return h.diaSemana == dia;
    }).toList()..sort((a, b) => a.horaInicio.compareTo(b.horaInicio));
  }

  Future<void> _openDayModal(
    BuildContext context,
    DateTime date,
    List<CitaModel> dayCitas,
    List<HorarioModel> dayHorarios,
  ) {
    onSelectedDateChanged(date);
    return showAppModal<void>(
      context,
      title: _longDateLabel(date),
      subtitle:
          '${dayCitas.length} citas - ${dayHorarios.length} bloques laborales',
      child: HorarioDayDetailModal(
        date: date,
        citas: dayCitas,
        horarios: dayHorarios,
        empleados: empleados,
        readOnly: readOnly,
        onHorarioTap: onHorarioTap,
        onCitaEdit: onCitaEdit,
        onCitaStatusChange: onCitaStatusChange,
      ),
    );
  }
}

class _CalendarToolbar extends StatelessWidget {
  const _CalendarToolbar({
    required this.visibleMonth,
    required this.empleados,
    required this.selectedEmpleadoId,
    required this.selectedEstado,
    required this.searchText,
    required this.readOnly,
    required this.onMonthChanged,
    required this.onEmpleadoFilterChanged,
    required this.onEstadoFilterChanged,
    required this.onSearchChanged,
    this.onNewHorario,
    this.onNewCita,
    this.onRefresh,
  });

  final DateTime visibleMonth;
  final Map<int, EmpleadoModel> empleados;
  final int? selectedEmpleadoId;
  final String? selectedEstado;
  final String searchText;
  final bool readOnly;
  final void Function(DateTime) onMonthChanged;
  final void Function(int?) onEmpleadoFilterChanged;
  final void Function(String?) onEstadoFilterChanged;
  final void Function(String) onSearchChanged;
  final VoidCallback? onNewHorario;
  final VoidCallback? onNewCita;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final monthText = '${_meses[visibleMonth.month - 1]} ${visibleMonth.year}';
    final filterWidth = isMobile ? double.infinity : 190.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _surfaceDecoration(context),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: isMobile ? double.infinity : 310,
            child: Row(
              children: [
                _IconPillButton(
                  icon: Icons.chevron_left,
                  tooltip: 'Mes anterior',
                  onPressed: () => onMonthChanged(
                    DateTime(visibleMonth.year, visibleMonth.month - 1),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            monthText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _IconPillButton(
                  icon: Icons.chevron_right,
                  tooltip: 'Mes siguiente',
                  onPressed: () => onMonthChanged(
                    DateTime(visibleMonth.year, visibleMonth.month + 1),
                  ),
                ),
              ],
            ),
          ),
          _ToolbarButton(
            icon: Icons.today_outlined,
            label: 'Hoy',
            onPressed: () {
              final now = DateTime.now();
              onMonthChanged(DateTime(now.year, now.month));
            },
          ),
          SizedBox(
            width: filterWidth,
            child: DropdownButtonFormField<int?>(
              key: ValueKey('empleado_$selectedEmpleadoId'),
              initialValue: selectedEmpleadoId,
              decoration: const InputDecoration(
                labelText: 'Empleado',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                ...empleados.values.map(
                  (e) => DropdownMenuItem<int?>(
                    value: e.idEmpleado,
                    child: Text(e.nombreCompleto),
                  ),
                ),
              ],
              onChanged: onEmpleadoFilterChanged,
            ),
          ),
          SizedBox(
            width: filterWidth,
            child: DropdownButtonFormField<String?>(
              key: ValueKey('estado_$selectedEstado'),
              initialValue: selectedEstado,
              decoration: const InputDecoration(
                labelText: 'Estado',
                prefixIcon: Icon(Icons.tune_outlined),
              ),
              items: const [
                DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                DropdownMenuItem(
                  value: 'confirmada',
                  child: Text('Confirmada'),
                ),
                DropdownMenuItem(
                  value: 'completada',
                  child: Text('Finalizada'),
                ),
                DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
                DropdownMenuItem(value: 'retrasada', child: Text('Retrasada')),
              ],
              onChanged: onEstadoFilterChanged,
            ),
          ),
          SizedBox(
            width: isMobile ? double.infinity : 230,
            child: TextFormField(
              initialValue: searchText,
              decoration: const InputDecoration(
                labelText: 'Buscar',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          if (onRefresh != null)
            _IconPillButton(
              icon: Icons.refresh,
              tooltip: 'Actualizar',
              onPressed: onRefresh,
            ),
          if (!readOnly && onNewHorario != null)
            FilledButton.icon(
              onPressed: onNewHorario,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Bloque'),
            ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.visibleMonth,
    required this.selectedDate,
    required this.citas,
    required this.horariosForDate,
    required this.empleados,
    required this.onSelectedDateChanged,
    required this.onOpenDay,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<CitaModel> citas;
  final List<HorarioModel> Function(DateTime) horariosForDate;
  final Map<int, EmpleadoModel> empleados;
  final void Function(DateTime) onSelectedDateChanged;
  final void Function(DateTime) onOpenDay;

  @override
  Widget build(BuildContext context) {
    final days = _monthDays(visibleMonth);

    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = 800.0;
        final gridWidth = math.max(constraints.maxWidth, minWidth);

        return Container(
          decoration: _surfaceDecoration(context),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: gridWidth,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: [
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        border: Border(
                          bottom: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                      ),
                      child: Row(
                        children: [
                          for (final day in _diasCorto)
                            Expanded(
                              child: Center(
                                child: Text(
                                  day,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: days.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1.15,
                      ),
                      itemBuilder: (context, index) {
                        final date = days[index];
                        final dayCitas = citas
                            .where((c) => c.fecha == _isoDate(date))
                            .toList()
                          ..sort((a, b) => a.hora.compareTo(b.hora));
                        return _MonthDayCell(
                          date: date,
                          isInMonth: date.month == visibleMonth.month,
                          isSelected: _sameDate(date, selectedDate),
                          isToday: _sameDate(date, DateTime.now()),
                          citas: dayCitas,
                          horarios: horariosForDate(date),
                          empleados: empleados,
                          onTap: () {
                            if (!_isDateInCurrentWeek(date)) return;
                            onSelectedDateChanged(date);
                            onOpenDay(date);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

bool _isDateInCurrentWeek(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // En Dart weekday: 1=Lunes, 7=Domingo.
  final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));
  
  final check = DateTime(date.year, date.month, date.day);
  return (check.isAtSameMomentAs(startOfWeek) || check.isAfter(startOfWeek)) &&
         (check.isAtSameMomentAs(endOfWeek) || check.isBefore(endOfWeek));
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.date,
    required this.isInMonth,
    required this.isSelected,
    required this.isToday,
    required this.citas,
    required this.horarios,
    required this.empleados,
    required this.onTap,
  });

  final DateTime date;
  final bool isInMonth;
  final bool isSelected;
  final bool isToday;
  final List<CitaModel> citas;
  final List<HorarioModel> horarios;
  final Map<int, EmpleadoModel> empleados;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPast = date.isBefore(today);
    final isCurrentWeek = _isDateInCurrentWeek(date);
    final hasActivity = citas.isNotEmpty || horarios.isNotEmpty;

    final ocupados = citas.map((c) => c.empleadoId).toSet().length;
    final visible = citas.take(2).toList();
    final hiddenCount = math.max(0, citas.length - visible.length);
    
    Color bg = Colors.transparent;
    if (isSelected) {
      bg = AppColors.primary.withValues(alpha: 0.08);
    } else if (isCurrentWeek) {
      bg = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25);
    }

    final double finalOpacity = isPast ? 0.2 : (isInMonth ? 1.0 : 0.25);

    return Opacity(
      opacity: finalOpacity,
      child: Material(
        color: bg,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor),
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _DayNumber(
                      day: date.day,
                      isToday: isToday,
                      isSelected: isSelected,
                    ),
                    const Spacer(),
                    if (hasActivity && !isSelected)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: citas.isNotEmpty
                              ? AppColors.primary
                              : AppColors.success.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (citas.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _TinyBadge(label: '${citas.length}'),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (citas.isEmpty)
                          _SoftLine(
                            text: horarios.isEmpty
                                ? 'Cerrado'
                                : '${horarios.length} bloques',
                            color: Theme.of(context).colorScheme.outline,
                          )
                        else ...[
                          Text(
                            ocupados == 1
                                ? '1 ocupado'
                                : '$ocupados ocupados',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(height: 6),
                          for (final cita in visible)
                            _MiniCitaPreview(cita: cita, empleados: empleados),
                          if (hiddenCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '+$hiddenCount',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class _CalendarSidePanel extends StatelessWidget {
  const _CalendarSidePanel({
    required this.selectedDate,
    required this.citas,
    required this.horarios,
    required this.empleados,
    required this.onOpenDay,
  });

  final DateTime selectedDate;
  final List<CitaModel> citas;
  final List<HorarioModel> horarios;
  final Map<int, EmpleadoModel> empleados;
  final VoidCallback onOpenDay;

  @override
  Widget build(BuildContext context) {
    final empleadosDisponibles = horarios
        .map((h) => empleados[h.empleadoId])
        .whereType<EmpleadoModel>()
        .toList();

    return SizedBox(
      width: MediaQuery.sizeOf(context).width < 1100 ? 270 : 320,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _PanelBox(
              title: 'Leyenda',
              icon: Icons.palette_outlined,
              child: Column(
                children: [
                  _LegendItem('Pendiente', AppColors.info),
                  _LegendItem('Confirmada', AppColors.primary),
                  _LegendItem('Finalizada', AppColors.success),
                  _LegendItem('Cancelada', AppColors.error),
                  _LegendItem('Retrasada', AppColors.warning),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _PanelBox(
              title: _shortDateLabel(selectedDate),
              icon: Icons.event_note_outlined,
              trailing: TextButton(
                onPressed: onOpenDay,
                child: const Text('Abrir'),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetricRow(
                    label: 'Citas',
                    value: citas.length.toString(),
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  _MetricRow(
                    label: 'Empleados',
                    value: citas
                        .map((c) => c.empleadoId)
                        .toSet()
                        .length
                        .toString(),
                    color: AppColors.info,
                  ),
                  const SizedBox(height: 8),
                  _MetricRow(
                    label: 'Disponibles',
                    value: empleadosDisponibles.length.toString(),
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _PanelBox(
              title: 'Equipo disponible',
              icon: Icons.groups_outlined,
              child: empleadosDisponibles.isEmpty
                  ? _MutedText('No hay bloques laborales para este dia.')
                  : Column(
                      children: empleadosDisponibles.take(6).map((empleado) {
                        final bloques = horarios
                            .where((h) => h.empleadoId == empleado.idEmpleado)
                            .toList();
                        return _EmpleadoLine(
                          empleado: empleado,
                          subtitle: bloques
                              .map(
                                (h) =>
                                    '${Formatters.timeString(h.horaInicio)}-${Formatters.timeString(h.horaFin)}',
                              )
                              .join(' / '),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 12),
            _PanelBox(
              title: 'Citas del dia',
              icon: Icons.schedule_outlined,
              child: citas.isEmpty
                  ? _MutedText('Aun no hay citas agendadas.')
                  : Column(
                      children: citas.take(5).map((cita) {
                        return _CompactTimelineItem(
                          cita: cita,
                          empleado: empleados[cita.empleadoId],
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class HorarioDayDetailModal extends StatefulWidget {
  const HorarioDayDetailModal({
    super.key,
    required this.date,
    required this.citas,
    required this.horarios,
    required this.empleados,
    required this.readOnly,
    required this.onHorarioTap,
    required this.onCitaEdit,
    required this.onCitaStatusChange,
  });

  final DateTime date;
  final List<CitaModel> citas;
  final List<HorarioModel> horarios;
  final Map<int, EmpleadoModel> empleados;
  final bool readOnly;
  final void Function(HorarioModel) onHorarioTap;
  final void Function(CitaModel) onCitaEdit;
  final Future<bool> Function(CitaModel, String) onCitaStatusChange;

  @override
  State<HorarioDayDetailModal> createState() => _HorarioDayDetailModalState();
}

class _HorarioDayDetailModalState extends State<HorarioDayDetailModal> {
  late List<CitaModel> _citas;

  @override
  void initState() {
    super.initState();
    _citas = [...widget.citas];
  }

  @override
  Widget build(BuildContext context) {
    final empleadosAsignados = {
      for (final cita in _citas) cita.empleadoId,
      for (final horario in widget.horarios) horario.empleadoId,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SummaryChip(
              icon: Icons.event_outlined,
              label: '${_citas.length} citas',
              color: AppColors.primary,
            ),
            _SummaryChip(
              icon: Icons.groups_outlined,
              label: '${empleadosAsignados.length} empleados',
              color: AppColors.info,
            ),
            _SummaryChip(
              icon: Icons.watch_later_outlined,
              label: '${_citas.where(_isLate).length} alertas',
              color: AppColors.warning,
            ),
            if (!widget.readOnly)
              _SummaryActionChip(
                icon: Icons.add_circle_outline,
                label: 'Agendar cita',
                color: AppColors.primary,
                onTap: () => context.push(RouteNames.citas),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Horarios laborales',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (widget.horarios.isEmpty)
          _EmptyPanel(
            icon: Icons.event_busy_outlined,
            text: 'Sin disponibilidad laboral para este dia.',
          )
        else
          Column(
            children: widget.horarios.map((horario) {
              final empleado = widget.empleados[horario.empleadoId];
              return _HorarioBlockCard(
                horario: horario,
                empleado: empleado,
                readOnly: widget.readOnly,
                onTap: () => widget.onHorarioTap(horario),
              );
            }).toList(),
          ),
        const SizedBox(height: 22),
        Text(
          'Citas y reservas',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (_citas.isEmpty)
          _EmptyPanel(
            icon: Icons.inbox_outlined,
            text: 'No hay citas para revisar.',
          )
        else
          Column(
            children: _citas.map((cita) {
              return _CitaDetailCard(
                cita: cita,
                empleado: widget.empleados[cita.empleadoId],
                readOnly: widget.readOnly,
                onEdit: () => widget.onCitaEdit(cita),
                onStatusChange: (estado) async {
                  final ok = await widget.onCitaStatusChange(cita, estado);
                  if (!mounted || !ok) return;
                  setState(() {
                    _citas = _citas
                        .map(
                          (item) => item.idCita == cita.idCita
                              ? item.copyWith(estado: estado)
                              : item,
                        )
                        .toList();
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _MobileAgenda extends StatelessWidget {
  const _MobileAgenda({
    required this.visibleMonth,
    required this.selectedDate,
    required this.citas,
    required this.horariosForDate,
    required this.empleados,
    required this.onSelectedDateChanged,
    required this.onOpenDay,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<CitaModel> citas;
  final List<HorarioModel> Function(DateTime) horariosForDate;
  final Map<int, EmpleadoModel> empleados;
  final void Function(DateTime) onSelectedDateChanged;
  final void Function(DateTime) onOpenDay;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      DateUtils.getDaysInMonth(visibleMonth.year, visibleMonth.month),
      (index) => DateTime(visibleMonth.year, visibleMonth.month, index + 1),
    );

    return ListView.separated(
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final date = days[index];
        final dayCitas = citas.where((c) => c.fecha == _isoDate(date)).toList()
          ..sort((a, b) => a.hora.compareTo(b.hora));
        final dayHorarios = horariosForDate(date);
        return _MobileDayCard(
          date: date,
          isSelected: _sameDate(date, selectedDate),
          citas: dayCitas,
          horarios: dayHorarios,
          empleados: empleados,
          onTap: () {
            if (!_isDateInCurrentWeek(date)) return;
            onSelectedDateChanged(date);
            onOpenDay(date);
          },
        );
      },
    );
  }
}

class _MobileDayCard extends StatelessWidget {
  const _MobileDayCard({
    required this.date,
    required this.isSelected,
    required this.citas,
    required this.horarios,
    required this.empleados,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final List<CitaModel> citas;
  final List<HorarioModel> horarios;
  final Map<int, EmpleadoModel> empleados;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _surfaceDecoration(
            context,
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateTile(date: date),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${citas.length} citas - ${horarios.length} bloques',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (citas.isEmpty)
                      _MutedText('Sin citas agendadas.')
                    else
                      for (final cita in citas.take(2))
                        _MiniCitaPreview(cita: cita, empleados: empleados),
                    if (citas.length > 2)
                      Text(
                        '+${citas.length - 2} mas',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _CitaDetailCard extends StatefulWidget {
  const _CitaDetailCard({
    required this.cita,
    required this.empleado,
    required this.readOnly,
    required this.onEdit,
    required this.onStatusChange,
  });

  final CitaModel cita;
  final EmpleadoModel? empleado;
  final bool readOnly;
  final VoidCallback onEdit;
  final Future<void> Function(String) onStatusChange;

  @override
  State<_CitaDetailCard> createState() => _CitaDetailCardState();
}

class _CitaDetailCardState extends State<_CitaDetailCard> {
  bool _expanded = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(widget.cita);
    final cliente = _clienteLabel(widget.cita);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _surfaceDecoration(
        context,
        color: color.withValues(alpha: 0.06),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: _expanded ? 118 : 76,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cliente,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _StatusBadge(cita: widget.cita),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${Formatters.timeString(widget.cita.hora)} - ${widget.empleado?.nombreCompleto ?? 'Empleado #${widget.cita.empleadoId}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_expanded) ...[
                  const SizedBox(height: 10),
                  _DetailLine(
                    icon: Icons.spa_outlined,
                    text: _serviciosLabel(widget.cita),
                  ),
                  _DetailLine(
                    icon: Icons.timer_outlined,
                    text: 'Duracion estimada pendiente',
                  ),
                  _DetailLine(
                    icon: _isLate(widget.cita)
                        ? Icons.warning_amber_outlined
                        : Icons.check_circle_outline,
                    text: _isLate(widget.cita)
                        ? 'Alerta: cita retrasada'
                        : 'Sin alertas operativas',
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() => _expanded = !_expanded),
                      icon: Icon(
                        _expanded
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                      ),
                      label: Text(_expanded ? 'Ocultar' : 'Ver detalles'),
                    ),
                    if (!widget.readOnly)
                      OutlinedButton.icon(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Editar'),
                      ),
                    if (!widget.readOnly)
                      PopupMenuButton<String>(
                        enabled: !_saving,
                        onSelected: (value) async {
                          if (value == 'editar' ||
                              value == 'reprogramar' ||
                              value == 'empleado') {
                            widget.onEdit();
                            return;
                          }
                          setState(() => _saving = true);
                          await widget.onStatusChange(value);
                          if (mounted) setState(() => _saving = false);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'confirmada',
                            child: Text('Confirmar'),
                          ),
                          PopupMenuItem(
                            value: 'completada',
                            child: Text('Finalizar'),
                          ),
                          PopupMenuItem(
                            value: 'pendiente',
                            child: Text('Marcar pendiente'),
                          ),
                          PopupMenuItem(
                            value: 'cancelada',
                            child: Text('Cancelar'),
                          ),
                          PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'reprogramar',
                            child: Text('Reprogramar'),
                          ),
                          PopupMenuItem(
                            value: 'empleado',
                            child: Text('Cambiar empleado'),
                          ),
                        ],
                        child: _InlineAction(
                          icon: _saving
                              ? Icons.hourglass_empty_outlined
                              : Icons.more_horiz,
                          label: _saving ? 'Guardando' : 'Acciones',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HorarioBlockCard extends StatelessWidget {
  const _HorarioBlockCard({
    required this.horario,
    required this.empleado,
    required this.readOnly,
    required this.onTap,
  });

  final HorarioModel horario;
  final EmpleadoModel? empleado;
  final bool readOnly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _surfaceDecoration(
        context,
        color: AppColors.success.withValues(alpha: 0.06),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.success.withValues(alpha: 0.14),
          foregroundColor: AppColors.success,
          child: const Icon(Icons.work_outline, size: 20),
        ),
        title: Text(
          empleado?.nombreCompleto ?? 'Empleado #${horario.empleadoId}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${Formatters.timeString(horario.horaInicio)} - ${Formatters.timeString(horario.horaFin)}',
        ),
        trailing: readOnly ? null : const Icon(Icons.edit_outlined),
        onTap: readOnly ? null : onTap,
      ),
    );
  }
}

class _PanelBox extends StatelessWidget {
  const _PanelBox({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmpleadoLine extends StatelessWidget {
  const _EmpleadoLine({required this.empleado, required this.subtitle});

  final EmpleadoModel empleado;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            foregroundColor: AppColors.primary,
            child: Text(
              empleado.nombre.isEmpty ? '?' : empleado.nombre[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  empleado.nombreCompleto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactTimelineItem extends StatelessWidget {
  const _CompactTimelineItem({required this.cita, required this.empleado});

  final CitaModel cita;
  final EmpleadoModel? empleado;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(cita);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Formatters.timeString(cita.hora)} - ${_clienteLabel(cita)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  empleado?.nombreCompleto ?? 'Empleado #${cita.empleadoId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCitaPreview extends StatelessWidget {
  const _MiniCitaPreview({required this.cita, required this.empleados});

  final CitaModel cita;
  final Map<int, EmpleadoModel> empleados;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(cita);
    final empleado = empleados[cita.empleadoId];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        '${Formatters.timeString(cita.hora)} - ${empleado?.nombre ?? _clienteLabel(cita)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.cita});

  final CitaModel cita;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(cita);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(cita),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _IconPillButton extends StatelessWidget {
  const _IconPillButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _DayNumber extends StatelessWidget {
  const _DayNumber({
    required this.day,
    required this.isToday,
    required this.isSelected,
  });

  final int day;
  final bool isToday;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final active = isToday || isSelected;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Text(
        day.toString(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: active ? Colors.white : null,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SoftLine extends StatelessWidget {
  const _SoftLine({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _diasCorto[date.weekday - 1],
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            date.day.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(context),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

List<DateTime> _monthDays(DateTime month) {
  final first = DateTime(month.year, month.month);
  final start = first.subtract(Duration(days: first.weekday - 1));
  return List.generate(42, (index) => start.add(Duration(days: index)));
}

String _isoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

bool _sameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _shortDateLabel(DateTime date) {
  return '${_diasCorto[date.weekday - 1]} ${date.day}, ${_meses[date.month - 1]}';
}

String _longDateLabel(DateTime date) {
  final dia = _diasOrden[date.weekday - 1];
  return '${dia[0].toUpperCase()}${dia.substring(1)} ${date.day}';
}

class _SummaryActionChip extends StatelessWidget {
  const _SummaryActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String _clienteLabel(CitaModel cita) {
  final nombre = '${cita.clienteNombre ?? ''} ${cita.clienteApellido ?? ''}'
      .trim();
  return nombre.isEmpty ? 'Cliente #${cita.clienteId}' : nombre;
}

String _serviciosLabel(CitaModel cita) {
  final servicios = cita.serviciosResumen;
  if (servicios == null || servicios.isEmpty) return 'Servicios por asignar';
  return servicios.join(', ');
}

String _visualEstado(CitaModel cita) {
  if (_isLate(cita)) return 'retrasada';
  return cita.estado;
}

String _statusLabel(CitaModel cita) {
  final visual = _visualEstado(cita);
  if (visual == 'retrasada') return 'Retrasada';
  return CitaEstados.labelFor(cita.estado);
}

Color _statusColor(CitaModel cita) {
  final visual = _visualEstado(cita);
  if (visual == 'retrasada') return AppColors.warning;
  return CitaEstados.colorFor(cita.estado);
}

bool _isLate(CitaModel cita) {
  if (cita.estado == 'cancelada' || cita.estado == 'completada') return false;
  final time = cita.hora.length == 5 ? '${cita.hora}:00' : cita.hora;
  final dateTime = DateTime.tryParse('${cita.fecha}T$time');
  if (dateTime == null) return false;
  return dateTime.isBefore(DateTime.now());
}

BoxDecoration _surfaceDecoration(BuildContext context, {Color? color}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: color ?? Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.045),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );
}
