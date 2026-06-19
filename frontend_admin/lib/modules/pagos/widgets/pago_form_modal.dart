import 'package:flutter/material.dart';

import '../models/pago_model.dart';

class PagoFormModal extends StatefulWidget {
  const PagoFormModal({super.key, required this.onSubmit});
  final Future<bool> Function(PagoModel) onSubmit;

  @override
  State<PagoFormModal> createState() => _PagoFormModalState();
}

class _PagoFormModalState extends State<PagoFormModal> {
  final _facturaId = TextEditingController();
  final _monto = TextEditingController();
  final _fecha = TextEditingController();
  String _metodo = 'efectivo';
  String _estado = 'completado';

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _fecha.text =
        '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _facturaId.dispose();
    _monto.dispose();
    _fecha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _facturaId,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'ID Factura *'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _monto,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monto *'),
        ),
        const SizedBox(height: 12),
        TextField(controller: _fecha, decoration: const InputDecoration(labelText: 'Fecha *')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('metodo_$_metodo'),
          initialValue: _metodo,
          decoration: const InputDecoration(labelText: 'Método'),
          items: const [
            DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
            DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
            DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
          ],
          onChanged: (v) => setState(() => _metodo = v ?? 'efectivo'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('pago_estado_$_estado'),
          initialValue: _estado,
          decoration: const InputDecoration(labelText: 'Estado'),
          items: const [
            DropdownMenuItem(value: 'completado', child: Text('Completado')),
            DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
          ],
          onChanged: (v) => setState(() => _estado = v ?? 'completado'),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () async {
            final model = PagoModel(
              idPago: 0,
              facturaId: int.parse(_facturaId.text),
              metodo: _metodo,
              estado: _estado,
              fecha: _fecha.text.trim(),
              monto: double.parse(_monto.text),
            );
            final ok = await widget.onSubmit(model);
            if (!context.mounted) return;
            if (ok) Navigator.pop(context, true);
          },
          child: const Text('Registrar pago'),
        ),
      ],
    );
  }
}
