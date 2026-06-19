import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/validators.dart';
import '../models/producto_model.dart';

class ProductoFormModal extends StatefulWidget {
  const ProductoFormModal({super.key, this.producto, required this.onSubmit});
  final ProductoModel? producto;
  final Future<bool> Function(ProductoModel) onSubmit;

  @override
  State<ProductoFormModal> createState() => _ProductoFormModalState();
}

class _ProductoFormModalState extends State<ProductoFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _precio;
  late final TextEditingController _stock;
  late final TextEditingController _stockMin;
  String _tipo = 'manual';
  String _estado = 'activo';

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombre = TextEditingController(text: p?.nombre ?? '');
    _precio = TextEditingController(text: p?.precio.toString() ?? '');
    _stock = TextEditingController(text: p?.stock.toString() ?? '0');
    _stockMin = TextEditingController(text: p?.stockMinimo.toString() ?? '5');
    _tipo = p?.tipoControl ?? 'manual';
    _estado = p?.estado ?? 'activo';
  }

  @override
  void dispose() {
    _nombre.dispose();
    _precio.dispose();
    _stock.dispose();
    _stockMin.dispose();
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
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ ]')),
            ],
            validator: (v) {
              final res = Validators.required(v, field: 'Nombre');
              if (res != null) return res;
              if (v!.trim().length < 3) return 'Mínimo 3 caracteres';
              final regex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$');
              if (!regex.hasMatch(v.trim())) return 'Solo letras y espacios';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _precio,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              LengthLimitingTextInputFormatter(11), // 99,999,999.99
            ],
            decoration: const InputDecoration(labelText: 'Precio *', prefixText: '\$ '),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              final val = double.tryParse(v);
              if (val == null) return 'Formato inválido';
              if (val <= 0) return 'Debe ser mayor a 0';
              if (val > 99999999.99) return 'Precio demasiado alto';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _stock,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6), // 999,999
            ],
            decoration: const InputDecoration(labelText: 'Stock Inicial'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              final val = int.tryParse(v);
              if (val == null) return 'Inválido';
              if (val < 0) return 'Mínimo 0';
              if (val > 999999) return 'Máximo 999,999';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _stockMin,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(labelText: 'Stock Mínimo (Alerta)'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              final val = int.tryParse(v);
              if (val == null) return 'Inválido';
              if (val < 0) return 'Mínimo 0';
              if (val > 999999) return 'Máximo 999,999';
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('tipo_$_tipo'),
            initialValue: _tipo,
            decoration: const InputDecoration(labelText: 'Tipo control'),
            items: const [
              DropdownMenuItem(value: 'manual', child: Text('Manual')),
              DropdownMenuItem(value: 'unitario', child: Text('Unitario')),
            ],
            onChanged: (v) => setState(() => _tipo = v ?? 'manual'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('estado_prod_$_estado'),
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
            onPressed: () async {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              final model = ProductoModel(
                idProducto: widget.producto?.idProducto ?? 0,
                nombre: _nombre.text.trim(),
                precio: double.tryParse(_precio.text) ?? 0,
                stock: int.tryParse(_stock.text) ?? 0,
                stockMinimo: int.tryParse(_stockMin.text) ?? 5,
                tipoControl: _tipo,
                estado: _estado,
              );
              final ok = await widget.onSubmit(model);
              if (!context.mounted) return;
              if (ok) Navigator.pop(context, true);
            },
            child: const Text('Guardar producto'),
          ),
        ],
      ),
    );
  }
}
