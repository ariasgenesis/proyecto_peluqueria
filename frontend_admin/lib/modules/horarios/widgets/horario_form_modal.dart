import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../empleados/models/empleado_model.dart';
import '../../empleados/services/empleado_service.dart';
import '../models/horario_model.dart';

const _dias = [
  'lunes',
  'martes',
  'miercoles',
  'jueves',
  'viernes',
  'sabado',
  'domingo',
];

class HorarioFormModal extends ConsumerStatefulWidget {
  const HorarioFormModal({super.key, this.horario, required this.onSubmit});
  final HorarioModel? horario;
  final Future<bool> Function(HorarioModel) onSubmit;

  @override
  ConsumerState<HorarioFormModal> createState() => _HorarioFormModalState();
}

class _HorarioFormModalState extends ConsumerState<HorarioFormModal> {
  List<EmpleadoModel> _empleados = [];
  int? _empleadoId;
  String _dia = 'lunes';
  late final TextEditingController _inicio;
  late final TextEditingController _fin;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final h = widget.horario;
    _empleadoId = h?.empleadoId;
    _dia = h?.diaSemana ?? 'lunes';
    _inicio = TextEditingController(
      text: h?.horaInicio.substring(0, 5) ?? '08:00',
    );
    _fin = TextEditingController(text: h?.horaFin.substring(0, 5) ?? '17:00');
    _load();
  }

  Future<void> _load() async {
    final e = await ref.read(empleadoServiceProvider).listar(perPage: 100);
    if (mounted) setState(() => _empleados = e.data);
  }

  @override
  void dispose() {
    _inicio.dispose();
    _fin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return Column(
      children: [
        if (_error != null) ...[
          _InlineError(message: _error!),
          const SizedBox(height: 14),
        ],
        DropdownButtonFormField<int>(
          key: ValueKey('horario_empleado_$_empleadoId'),
          initialValue: _empleadoId,
          decoration: const InputDecoration(labelText: 'Empleado'),
          items: _empleados
              .map(
                (e) => DropdownMenuItem(
                  value: e.idEmpleado,
                  child: Text(e.nombreCompleto),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _empleadoId = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('horario_dia_$_dia'),
          initialValue: _dia,
          decoration: const InputDecoration(labelText: 'Día'),
          items: List.generate(7, (i) {
            final dayValue = _dias[i];
            final date = monday.add(Duration(days: i));
            final label = '${dayValue[0].toUpperCase()}${dayValue.substring(1)} ${date.day}';
            return DropdownMenuItem(
              value: dayValue,
              child: Text(label),
            );
          }),
          onChanged: (v) => setState(() => _dia = v ?? 'lunes'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _inicio,
          decoration: const InputDecoration(labelText: 'Inicio HH:mm'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _fin,
          decoration: const InputDecoration(labelText: 'Fin HH:mm'),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  if (_empleadoId == null) {
                    setState(
                      () => _error =
                          'Selecciona un empleado para el bloque semanal.',
                    );
                    return;
                  }
                  if (!_isValidTime(_inicio.text) || !_isValidTime(_fin.text)) {
                    setState(
                      () => _error = 'Usa horas validas con formato HH:mm.',
                    );
                    return;
                  }
                  setState(() {
                    _saving = true;
                    _error = null;
                  });
                  final model = HorarioModel(
                    idHorario: widget.horario?.idHorario ?? 0,
                    empleadoId: _empleadoId!,
                    diaSemana: _dia,
                    horaInicio: _inicio.text.trim(),
                    horaFin: _fin.text.trim(),
                  );
                  final ok = await widget.onSubmit(model);
                  if (!context.mounted) return;
                  if (ok) {
                    Navigator.pop(context, true);
                  } else {
                    setState(() {
                      _error =
                          'No se pudo guardar el bloque. Revisa duplicados o permisos.';
                      _saving = false;
                    });
                  }
                },
          child: Text(_saving ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }

  bool _isValidTime(String value) {
    final match = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value.trim());
    return match;
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}
