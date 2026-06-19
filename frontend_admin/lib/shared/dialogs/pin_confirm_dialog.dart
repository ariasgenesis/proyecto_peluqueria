import 'package:flutter/material.dart';

import 'app_modal_sheet.dart';

/// Solicita PIN de empleado antes de operaciones sensibles.
Future<Map<String, dynamic>?> showPinConfirmDialog(
  BuildContext context, {
  String title = 'Confirmar con PIN',
  String message = 'Ingrese el PIN del empleado responsable',
}) {
  return showAppModal<Map<String, dynamic>>(
    context,
    title: title,
    child: _PinForm(message: message),
  );
}

class _PinForm extends StatefulWidget {
  const _PinForm({required this.message});
  final String message;

  @override
  State<_PinForm> createState() => _PinFormState();
}

class _PinFormState extends State<_PinForm> {
  final _pinController = TextEditingController();
  final _empleadoIdController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    _empleadoIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.message),
        const SizedBox(height: 16),
        TextField(
          controller: _pinController,
          decoration: const InputDecoration(labelText: 'PIN *'),
          obscureText: true,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _empleadoIdController,
          decoration: const InputDecoration(
            labelText: 'ID empleado (opcional)',
            hintText: 'Solo si valida PIN de otro estilista',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            if (_pinController.text.trim().isEmpty) return;
            final pinEmpleadoId = int.tryParse(_empleadoIdController.text.trim());
            Navigator.pop(context, {
              'pin': _pinController.text.trim(),
              'pin_empleado_id': ?pinEmpleadoId,
            });
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
