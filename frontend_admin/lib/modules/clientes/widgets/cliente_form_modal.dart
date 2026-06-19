import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/validators.dart';
import '../models/cliente_model.dart';

class ClienteFormModal extends StatefulWidget {
  const ClienteFormModal({super.key, this.cliente, required this.onSubmit});
  final ClienteModel? cliente;
  final Future<bool> Function(ClienteModel) onSubmit;

  @override
  State<ClienteFormModal> createState() => _ClienteFormModalState();
}

class _ClienteFormModalState extends State<ClienteFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _apellido;
  late final TextEditingController _telefono;
  late final TextEditingController _direccion;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _nombre = TextEditingController(text: c?.nombre ?? '');
    _apellido = TextEditingController(text: c?.apellido ?? '');
    _telefono = TextEditingController(text: c?.telefono ?? '');
    _direccion = TextEditingController(text: c?.direccion ?? '');
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _telefono.dispose();
    _direccion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
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
            controller: _telefono,
            decoration: const InputDecoration(labelText: 'Teléfono'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) => Validators.telefonoOpcional(v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _direccion,
            decoration: const InputDecoration(labelText: 'Dirección'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading
                ? null
                : () async {
                    if (!(_formKey.currentState?.validate() ?? false)) return;
                    setState(() => _loading = true);
                    final model = ClienteModel(
                      idCliente: widget.cliente?.idCliente ?? 0,
                      nombre: _nombre.text.trim(),
                      apellido: _apellido.text.trim(),
                      telefono: _telefono.text.trim().isEmpty ? null : _telefono.text.trim(),
                      direccion: _direccion.text.trim().isEmpty ? null : _direccion.text.trim(),
                    );
                    final ok = await widget.onSubmit(model);
                    if (!context.mounted) return;
                    setState(() => _loading = false);
                    if (ok) {
                      Navigator.pop(context, true);
                    }
                  },
            child: Text(widget.cliente == null ? 'Crear cliente' : 'Guardar'),
          ),
        ],
      ),
    );
  }
}
