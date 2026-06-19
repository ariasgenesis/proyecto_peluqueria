import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/validators.dart';
import '../models/servicio_model.dart';

class ServicioFormModal extends StatefulWidget {
  const ServicioFormModal({super.key, this.servicio, required this.onSubmit});
  final ServicioModel? servicio;
  final Future<bool> Function(ServicioModel) onSubmit;

  @override
  State<ServicioFormModal> createState() => _ServicioFormModalState();
}

class _ServicioFormModalState extends State<ServicioFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late final TextEditingController _precio;
  late final TextEditingController _duracion;
  String _estado = 'activo';
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.servicio;
    _nombre = TextEditingController(text: s?.nombre ?? '');
    _descripcion = TextEditingController(text: s?.descripcion ?? '');
    _precio = TextEditingController(text: s?.precio.toString() ?? '');
    _duracion = TextEditingController(text: s?.duracion.toString() ?? '30');
    _estado = s?.estado ?? 'activo';
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _precio.dispose();
    _duracion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_error != null) ...[
            _InlineError(message: _error!),
            const SizedBox(height: 14),
          ],
          TextFormField(
            controller: _nombre,
            decoration: const InputDecoration(labelText: 'Nombre *'),
            validator: (v) => Validators.required(v, field: 'Nombre'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descripcion,
            decoration: const InputDecoration(labelText: 'Descripción'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _precio,
            decoration: const InputDecoration(labelText: 'Precio *'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              if (double.tryParse(v) == null) return 'Precio inválido';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _duracion,
            decoration: const InputDecoration(labelText: 'Duración (min) *'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              if (int.tryParse(v) == null) return 'Duración inválida';
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('servicio_estado_$_estado'),
            initialValue: _estado,
            decoration: const InputDecoration(labelText: 'Estado'),
            items: const [
              DropdownMenuItem(value: 'activo', child: Text('Activo')),
              DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
            ],
            onChanged: (v) => setState(() => _estado = v ?? 'activo'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    if (!(_formKey.currentState?.validate() ?? false)) return;
                    setState(() {
                      _saving = true;
                      _error = null;
                    });
                    final model = ServicioModel(
                      idServicio: widget.servicio?.idServicio ?? 0,
                      nombre: _nombre.text.trim(),
                      descripcion: _descripcion.text.trim().isEmpty
                          ? null
                          : _descripcion.text.trim(),
                      precio: double.parse(_precio.text),
                      duracion: int.parse(_duracion.text),
                      estado: _estado,
                    );
                    final ok = await widget.onSubmit(model);
                    if (!context.mounted) return;
                    if (ok) {
                      Navigator.pop(context, true);
                    } else {
                      setState(() {
                        _error =
                            'No se pudo guardar el servicio. Revisa permisos y datos ingresados.';
                        _saving = false;
                      });
                    }
                  },
            child: Text(_saving ? 'Guardando...' : 'Guardar servicio'),
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
