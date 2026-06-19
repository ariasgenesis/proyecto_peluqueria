import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/dialogs/app_confirm_dialog.dart';
import '../../../shared/dialogs/app_modal_sheet.dart';
import '../../../shared/layouts/admin_shell_layout.dart';
import '../../../shared/providers/lookup_provider.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../citas/models/cita_model.dart';
import '../../citas/services/cita_service.dart';
import '../../citas/widgets/cita_form_modal.dart';
import '../controllers/horario_controller.dart';
import '../models/horario_model.dart';
import '../services/horario_service.dart';
import '../widgets/horario_form_modal.dart';
import '../widgets/horario_month_calendar.dart';

class HorarioCalendarPage extends ConsumerStatefulWidget {
  const HorarioCalendarPage({super.key});

  @override
  ConsumerState<HorarioCalendarPage> createState() =>
      _HorarioCalendarPageState();
}

class _HorarioCalendarPageState extends ConsumerState<HorarioCalendarPage> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;
  int? _empleadoId;
  String? _estado;
  String _search = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final horariosAsync = ref.watch(horarioListProvider);
    final citasAsync = ref.watch(horarioCitasProvider);
    final empleadosAsync = ref.watch(empleadosLookupProvider);

    return AdminShellLayout(
      title: 'Horarios',
      currentRoute: '/horarios',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calendario administrativo',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAdmin
                            ? 'Gestiona horarios, disponibilidad y citas desde una vista mensual compacta.'
                            : 'Consulta tu agenda mensual y el detalle de cada jornada.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isAdmin)
                  const Chip(
                    avatar: Icon(Icons.visibility_outlined, size: 16),
                    label: Text('Solo visualizacion'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: horariosAsync.when(
              loading: () => const AppLoading(message: 'Cargando horarios...'),
              error: (e, _) => EmptyState(title: e.toString()),
              data: (horarios) => citasAsync.when(
                loading: () => const AppLoading(message: 'Cargando citas...'),
                error: (e, _) => EmptyState(title: e.toString()),
                data: (citas) => empleadosAsync.when(
                  loading: () => const AppLoading(),
                  error: (e, _) => EmptyState(title: e.toString()),
                  data: (empleados) {
                    if (empleados.isEmpty) {
                      return const EmptyState(
                        title: 'Sin empleados para mostrar agenda',
                      );
                    }
                    return HorarioMonthCalendar(
                      horarios: horarios,
                      citas: citas,
                      empleados: empleados,
                      visibleMonth: _visibleMonth,
                      selectedDate: _selectedDate,
                      selectedEmpleadoId: _empleadoId,
                      selectedEstado: _estado,
                      searchText: _search,
                      readOnly: !isAdmin,
                      onMonthChanged: _changeMonth,
                      onSelectedDateChanged: (date) =>
                          setState(() => _selectedDate = date),
                      onEmpleadoFilterChanged: (id) =>
                          setState(() => _empleadoId = id),
                      onEstadoFilterChanged: (estado) =>
                          setState(() => _estado = estado),
                      onSearchChanged: (value) =>
                          setState(() => _search = value),
                      onHorarioTap: (horario) =>
                          _openHorarioForm(context, ref, horario: horario),
                      onCitaEdit: (cita) =>
                          _openCitaForm(context, ref, cita: cita),
                      onCitaStatusChange: (cita, estado) =>
                          _changeCitaStatus(context, ref, cita, estado),
                      onNewHorario: isAdmin
                          ? () => _openHorarioForm(context, ref)
                          : null,
                      onNewCita: isAdmin
                          ? () => _openCitaForm(
                              context,
                              ref,
                              initialDate: _selectedDate,
                            )
                          : null,
                      onRefresh: _refresh,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _changeMonth(DateTime date) {
    setState(() {
      _visibleMonth = DateTime(date.year, date.month);
      final isExplicitDay = date.day > 1;
      final selectedInNewMonth =
          _selectedDate.year == date.year && _selectedDate.month == date.month;
      if (isExplicitDay) {
        _selectedDate = DateTime(date.year, date.month, date.day);
      } else if (!selectedInNewMonth) {
        _selectedDate = DateTime(date.year, date.month);
      }
    });
  }

  void _refresh() {
    ref.invalidate(horarioListProvider);
    ref.invalidate(horarioCitasProvider);
    ref.invalidate(empleadosLookupProvider);
  }

  Future<void> _openHorarioForm(
    BuildContext context,
    WidgetRef ref, {
    HorarioModel? horario,
  }) async {
    final service = ref.read(horarioServiceProvider);
    final ok = await showAppModal<bool>(
      context,
      title: horario == null ? 'Nuevo horario' : 'Editar horario',
      subtitle: 'Define empleado, dia y bloque laboral semanal.',
      child: HorarioFormModal(
        horario: horario,
        onSubmit: (h) async {
          try {
            if (horario == null) {
              await service.crear(h.toJson());
            } else {
              await service.actualizar(h.idHorario, h.toJson());
            }
            ref.invalidate(horarioListProvider);
            return true;
          } on ApiException catch (e) {
            if (context.mounted) SnackbarUtils.error(context, e.message);
            return false;
          }
        },
      ),
      actions: horario != null
          ? [
              TextButton(
                onPressed: () async {
                  if (!await showAppConfirmDialog(
                    context,
                    title: 'Eliminar',
                    message: 'Eliminar este bloque horario?',
                    destructive: true,
                  )) {
                    return;
                  }
                  await service.eliminar(horario.idHorario);
                  ref.invalidate(horarioListProvider);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ]
          : null,
    );
    if (ok == true && context.mounted) {
      SnackbarUtils.success(context, 'Horario guardado');
    }
  }

  Future<void> _openCitaForm(
    BuildContext context,
    WidgetRef ref, {
    CitaModel? cita,
    DateTime? initialDate,
  }) async {
    final service = ref.read(citaServiceProvider);
    final ok = await showAppModal<bool>(
      context,
      title: cita == null ? 'Nueva cita' : 'Editar cita #${cita.idCita}',
      subtitle: 'Ajusta cliente, empleado, fecha, hora y estado.',
      child: CitaFormModal(
        cita: cita,
        initialFecha: initialDate == null ? null : _isoDate(initialDate),
        onSubmit: (model) async {
          try {
            if (cita == null) {
              await service.crear(model.toJson());
            } else {
              await service.actualizar(cita.idCita, model.toJson());
            }
            ref.invalidate(horarioCitasProvider);
            return true;
          } on ApiException catch (e) {
            if (context.mounted) SnackbarUtils.error(context, e.message);
            return false;
          }
        },
      ),
    );
    if (ok == true && context.mounted) {
      SnackbarUtils.success(context, 'Cita guardada');
    }
  }

  Future<bool> _changeCitaStatus(
    BuildContext context,
    WidgetRef ref,
    CitaModel cita,
    String estado,
  ) async {
    if (cita.estado == estado) return true;
    try {
      await ref.read(citaServiceProvider).actualizar(cita.idCita, {
        'estado': estado,
      });
      ref.invalidate(horarioCitasProvider);
      if (context.mounted) {
        SnackbarUtils.success(context, 'Estado actualizado');
      }
      return true;
    } on ApiException catch (e) {
      if (context.mounted) SnackbarUtils.error(context, e.message);
      return false;
    }
  }

  String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
