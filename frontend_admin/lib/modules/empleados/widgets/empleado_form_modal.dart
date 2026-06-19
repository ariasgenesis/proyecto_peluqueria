import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../models/empleado_model.dart';

class EmpleadoFormModal extends StatefulWidget {
  const EmpleadoFormModal({
    super.key,
    this.empleado,
    required this.onSubmit,
  });

  final EmpleadoModel? empleado;
  final Future<bool> Function(EmpleadoModel empleado, String? pin) onSubmit;

  @override
  State<EmpleadoFormModal> createState() => _EmpleadoFormModalState();
}

class _EmpleadoFormModalState extends State<EmpleadoFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _apellido;
  late final TextEditingController _documento;
  late final TextEditingController _telefono;
  late final TextEditingController _cargo;
  late final TextEditingController _pin;
  late String _rol;
  bool _loading = false;

  bool get _esNuevo => widget.empleado == null;

  @override
  void initState() {
    super.initState();
    final e = widget.empleado;
    _nombre = TextEditingController(text: e?.nombre ?? '');
    _apellido = TextEditingController(text: e?.apellido ?? '');
    _documento = TextEditingController(text: e?.documento ?? '');
    _telefono = TextEditingController(text: e?.telefono ?? '');
    _cargo = TextEditingController(text: e?.cargo ?? '');
    _pin = TextEditingController();
    _rol = e?.rol ?? 'empleado';
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _documento.dispose();
    _telefono.dispose();
    _cargo.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final model = EmpleadoModel(
      idEmpleado: widget.empleado?.idEmpleado ?? 0,
      usuarioId: widget.empleado?.usuarioId ?? 0,
      nombre: _nombre.text.trim(),
      apellido: _apellido.text.trim(),
      documento: _documento.text.trim(),
      telefono: _telefono.text.trim().isEmpty ? null : _telefono.text.trim(),
      cargo: _cargo.text.trim().isEmpty ? null : _cargo.text.trim(),
      rol: _rol,
    );
    final ok = await widget.onSubmit(
      model,
      _pin.text.trim().isEmpty ? null : _pin.text.trim(),
    );
    if (mounted) setState(() => _loading = false);
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nombre,
            decoration: const InputDecoration(labelText: 'Nombre *'),
            validator: (v) => Validators.nombre(v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _apellido,
            decoration: const InputDecoration(labelText: 'Apellido *'),
            validator: (v) {
              final res = Validators.required(v, field: 'Apellido');
              if (res != null) return res;
              final regex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$');
              if (!regex.hasMatch(v!.trim())) return 'Solo letras';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _documento,
            decoration: const InputDecoration(labelText: 'Documento *'),
            enabled: _esNuevo,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) => Validators.documento(v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _rol,
            decoration: const InputDecoration(labelText: 'Rol *'),
            items: AppConstants.roles
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: _esNuevo
                ? (v) {
                    if (v != null) setState(() => _rol = v);
                  }
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telefono,
            decoration: const InputDecoration(labelText: 'Teléfono'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) => Validators.telefonoOpcional(v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cargo,
            decoration: const InputDecoration(labelText: 'Cargo'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pin,
            decoration: InputDecoration(
              labelText: _esNuevo ? 'PIN (4 dígitos) *' : 'PIN (solo si desea cambiar)',
            ),
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            validator: (v) => Validators.pin(v, requerido: _esNuevo),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(_esNuevo ? 'Registrar empleado' : 'Guardar cambios'),
          ),
        ],
      ),
    );
  }
}

