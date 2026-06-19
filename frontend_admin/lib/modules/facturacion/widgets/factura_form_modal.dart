import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/factura_model.dart';

class FacturaFormModal extends StatefulWidget {
  const FacturaFormModal({
    super.key,
    this.factura,
    required this.onSubmit,
    this.requirePin = true,
  });

  final FacturaModel? factura;
  final Future<bool> Function(FacturaModel factura, Map<String, dynamic>? pin)
  onSubmit;
  final bool requirePin;

  @override
  State<FacturaFormModal> createState() => _FacturaFormModalState();
}

class _FacturaFormModalState extends State<FacturaFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _citaId;
  late final TextEditingController _fecha;
  late final TextEditingController _total;
  late final TextEditingController _pin;
  String _estado = 'pendiente';
  String? _error;
  bool _saving = false;

  bool get _locked => widget.factura?.pagada ?? false;

  @override
  void initState() {
    super.initState();
    final f = widget.factura;
    final hoy = DateTime.now();
    _citaId = TextEditingController(text: f?.citaId.toString() ?? '');
    _fecha = TextEditingController(
      text:
          f?.fecha ??
          '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}',
    );
    _total = TextEditingController(text: f?.total.toString() ?? '');
    _pin = TextEditingController();
    _estado = f?.estado ?? 'pendiente';
  }

  @override
  void dispose() {
    _citaId.dispose();
    _fecha.dispose();
    _total.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final factura = widget.factura;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (factura != null) _FacturaSummary(factura: factura),
          if (_locked) ...[
            const SizedBox(height: 14),
            const _InlineInfo(
              icon: Icons.lock_outline,
              message:
                  'Factura pagada: la edicion y cancelacion quedan bloqueadas automaticamente.',
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            _InlineError(message: _error!),
          ],
          const SizedBox(height: 18),
          _SectionTitle(
            icon: Icons.receipt_long,
            title: 'Datos administrativos',
            subtitle: 'Informacion base de la factura y su estado operativo.',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _citaId,
            enabled: !_locked,
            decoration: const InputDecoration(labelText: 'ID Cita *'),
            keyboardType: TextInputType.number,
            validator: (v) => int.tryParse(v ?? '') == null
                ? 'Ingrese una cita valida'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fecha,
            enabled: !_locked,
            decoration: const InputDecoration(labelText: 'Fecha *'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _total,
            enabled: !_locked,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Total *'),
            validator: (v) => double.tryParse(v ?? '') == null
                ? 'Ingrese un total valido'
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('fac_estado_$_estado'),
            initialValue: _estado,
            decoration: const InputDecoration(labelText: 'Estado'),
            items: const [
              DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
              DropdownMenuItem(value: 'pagada', child: Text('Pagada')),
              DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
            ],
            onChanged: _locked
                ? null
                : (v) => setState(() => _estado = v ?? 'pendiente'),
          ),
          if (widget.requirePin && !_locked) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _pin,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'PIN empleado *'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'PIN requerido' : null,
            ),
          ],
          if (factura != null) ...[
            const SizedBox(height: 22),
            _SectionTitle(
              icon: Icons.history,
              title: 'Historial y movimientos',
              subtitle:
                  'Trazabilidad disponible desde el registro de la factura.',
            ),
            const SizedBox(height: 12),
            _AuditList(factura: factura),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _locked || _saving
                ? null
                : () async {
                    if (!(_formKey.currentState?.validate() ?? false)) return;
                    setState(() {
                      _saving = true;
                      _error = null;
                    });
                    final model = FacturaModel(
                      idFactura: widget.factura?.idFactura ?? 0,
                      citaId: int.parse(_citaId.text),
                      fecha: _fecha.text.trim(),
                      total: double.parse(_total.text),
                      estado: _estado,
                      generadaPor: widget.factura?.generadaPor,
                    );
                    final pinBody = widget.requirePin && _pin.text.isNotEmpty
                        ? {'pin': _pin.text.trim()}
                        : null;
                    final ok = await widget.onSubmit(model, pinBody);
                    if (!context.mounted) return;
                    if (ok) {
                      Navigator.pop(context, true);
                    } else {
                      setState(() {
                        _error =
                            'No se pudo guardar la factura. Revisa el PIN, permisos o estado actual.';
                        _saving = false;
                      });
                    }
                  },
            icon: Icon(_locked ? Icons.lock_outline : Icons.save_outlined),
            label: Text(
              _locked
                  ? 'Factura bloqueada'
                  : _saving
                  ? 'Guardando...'
                  : 'Guardar factura',
            ),
          ),
        ],
      ),
    );
  }
}

class _FacturaSummary extends StatelessWidget {
  const _FacturaSummary({required this.factura});

  final FacturaModel factura;

  @override
  Widget build(BuildContext context) {
    final statusColor = factura.pagada
        ? AppColors.success
        : factura.estado == 'cancelada'
        ? AppColors.error
        : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Factura #${factura.idFactura}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Chip(
                label: Text(factura.estado),
                backgroundColor: statusColor.withValues(alpha: 0.16),
                side: BorderSide.none,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoPill(
                icon: Icons.person_outline,
                label: 'Cliente',
                value: 'Desde cita #${factura.citaId}',
              ),
              _InfoPill(
                icon: Icons.spa_outlined,
                label: 'Servicios',
                value: 'Vinculados a la cita',
              ),
              _InfoPill(
                icon: Icons.inventory_2_outlined,
                label: 'Productos',
                value: 'Segun consumo registrado',
              ),
              _InfoPill(
                icon: Icons.badge_outlined,
                label: 'Empleado',
                value: factura.generadaPor == null
                    ? 'No disponible'
                    : '#${factura.generadaPor}',
              ),
              _InfoPill(
                icon: Icons.event_outlined,
                label: 'Fecha',
                value: Formatters.dateString(factura.fecha),
              ),
              _InfoPill(
                icon: Icons.payments_outlined,
                label: 'Metodo',
                value: factura.pagada ? 'Registrado' : 'Pendiente',
              ),
              _InfoPill(
                icon: Icons.sync_alt,
                label: 'Movimientos',
                value: factura.fechaModificacion == null
                    ? 'Sin cambios'
                    : 'Editada',
              ),
              _InfoPill(
                icon: Icons.attach_money,
                label: 'Total',
                value: Formatters.currency(factura.total),
              ),
              _InfoPill(
                icon: Icons.notes_outlined,
                label: 'Observaciones',
                value: factura.pagada ? 'Pago confirmado' : 'Sin observaciones',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuditList extends StatelessWidget {
  const _AuditList({required this.factura});

  final FacturaModel factura;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Creacion', factura.createdAt ?? factura.fecha, factura.generadaPor),
      if (factura.fechaModificacion != null)
        (
          'Ultima modificacion',
          factura.fechaModificacion!,
          factura.modificadaPor,
        ),
    ];
    return Column(
      children: items.map((item) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            radius: 16,
            child: Icon(Icons.history, size: 16),
          ),
          title: Text(item.$1),
          subtitle: Text(item.$2),
          trailing: Text(item.$3 == null ? 'Sistema' : 'Usuario #${item.$3}'),
        );
      }).toList(),
    );
  }
}

class _InlineInfo extends StatelessWidget {
  const _InlineInfo({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
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
