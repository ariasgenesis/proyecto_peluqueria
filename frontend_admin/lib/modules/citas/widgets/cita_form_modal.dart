import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../clientes/models/cliente_model.dart';
import '../../clientes/services/cliente_service.dart';
import '../../empleados/models/empleado_model.dart';
import '../../empleados/services/empleado_service.dart';
import '../models/cita_model.dart';

class CitaFormModal extends ConsumerStatefulWidget {
  const CitaFormModal({
    super.key,
    this.cita,
    this.initialFecha,
    required this.onSubmit,
  });

  final CitaModel? cita;
  final String? initialFecha;
  final Future<bool> Function(CitaModel) onSubmit;

  @override
  ConsumerState<CitaFormModal> createState() => _CitaFormModalState();
}

class _CitaFormModalState extends ConsumerState<CitaFormModal> {
  final _formKey = GlobalKey<FormState>();
  List<ClienteModel> _clientes = [];
  List<EmpleadoModel> _empleados = [];
  int? _clienteId;
  int? _empleadoId;
  late final TextEditingController _fecha;
  late final TextEditingController _hora;
  String _estado = 'pendiente';
  bool _loadingData = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.cita;
    _clienteId = c?.clienteId;
    _empleadoId = c?.empleadoId;
    _fecha = TextEditingController(
      text: c?.fecha ?? widget.initialFecha ?? _hoy(),
    );
    _hora = TextEditingController(
      text: c != null ? c.hora.substring(0, 5) : '09:00',
    );
    _estado = c?.estado ?? 'pendiente';
    _loadSelects();
  }

  String _hoy() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadSelects() async {
    final clientes = await ref
        .read(clienteServiceProvider)
        .listar(perPage: 100);
    final empleados = await ref
        .read(empleadoServiceProvider)
        .listar(perPage: 100);
    if (mounted) {
      setState(() {
        _clientes = clientes.data;
        _empleados = empleados.data;
        _loadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _fecha.dispose();
    _hora.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) return const Center(child: CircularProgressIndicator());

    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_error != null) ...[
            _InlineError(message: _error!),
            const SizedBox(height: 14),
          ],
          DropdownButtonFormField<int>(
            key: ValueKey('cliente_$_clienteId'),
            initialValue: _clienteId,
            decoration: const InputDecoration(labelText: 'Cliente *'),
            items: _clientes
                .map(
                  (c) => DropdownMenuItem(
                    value: c.idCliente,
                    child: Text(c.nombreCompleto),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _clienteId = v),
            validator: (v) => v == null ? 'Seleccione cliente' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: ValueKey('empleado_$_empleadoId'),
            initialValue: _empleadoId,
            decoration: const InputDecoration(labelText: 'Empleado *'),
            items: _empleados
                .map(
                  (e) => DropdownMenuItem(
                    value: e.idEmpleado,
                    child: Text(e.nombreCompleto),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _empleadoId = v),
            validator: (v) => v == null ? 'Seleccione empleado' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fecha,
            decoration: const InputDecoration(
              labelText: 'Fecha (YYYY-MM-DD) *',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _hora,
            decoration: const InputDecoration(labelText: 'Hora (HH:mm) *'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('estado_$_estado'),
            initialValue: _estado,
            decoration: const InputDecoration(labelText: 'Estado'),
            items: const [
              DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
              DropdownMenuItem(value: 'confirmada', child: Text('Confirmada')),
              DropdownMenuItem(value: 'completada', child: Text('Finalizada')),
              DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
            ],
            onChanged: (v) => setState(() => _estado = v ?? 'pendiente'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    if (!(_formKey.currentState?.validate() ?? false)) return;
                    if (_clienteId == null || _empleadoId == null) return;
                    setState(() {
                      _saving = true;
                      _error = null;
                    });
                    final model = CitaModel(
                      idCita: widget.cita?.idCita ?? 0,
                      clienteId: _clienteId!,
                      empleadoId: _empleadoId!,
                      fecha: _fecha.text.trim(),
                      hora: _hora.text.trim(),
                      estado: _estado,
                    );
                    final ok = await widget.onSubmit(model);
                    if (!context.mounted) return;
                    if (ok) {
                      Navigator.pop(context, true);
                    } else {
                      setState(() {
                        _error =
                            'No se pudo guardar la cita. Valida disponibilidad, fecha, hora y permisos.';
                        _saving = false;
                      });
                    }
                  },
            child: Text(
              _saving
                  ? 'Guardando...'
                  : widget.cita == null
                  ? 'Crear cita'
                  : 'Guardar',
            ),
          ),
        ],
      ),
    );
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
