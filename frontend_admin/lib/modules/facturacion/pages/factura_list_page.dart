import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/dialogs/app_confirm_dialog.dart';
import '../../../shared/dialogs/app_modal_sheet.dart';
import '../../../shared/dialogs/pin_confirm_dialog.dart';
import '../../../shared/layouts/admin_shell_layout.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/factura_model.dart';
import '../services/factura_service.dart';
import '../widgets/factura_form_modal.dart';

final facturaListProvider = FutureProvider<List<FacturaModel>>((ref) async {
  final res = await ref.watch(facturaServiceProvider).listar();
  return res.data;
});

class FacturaListPage extends ConsumerWidget {
  const FacturaListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(facturaListProvider);

    return AdminShellLayout(
      title: 'Facturacion',
      currentRoute: '/facturacion',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Controla facturas, estados de pago y trazabilidad administrativa.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _open(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva factura'),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const AppLoading(),
              error: (e, _) =>
                  EmptyState(title: e.toString(), icon: Icons.cloud_off),
              data: (items) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (_, i) => _FacturaCard(
                  factura: items[i],
                  onTap: () => _open(context, ref, factura: items[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref, {
    FacturaModel? factura,
  }) async {
    final service = ref.read(facturaServiceProvider);
    final ok = await showAppModal<bool>(
      context,
      title: factura == null
          ? 'Nueva factura'
          : 'Factura #${factura.idFactura}',
      subtitle: factura?.pagada == true
          ? 'Vista administrativa completa. Esta factura ya esta pagada y bloqueada.'
          : 'Gestiona datos, estado, PIN y trazabilidad sin salir del flujo.',
      child: FacturaFormModal(
        factura: factura,
        onSubmit: (f, pin) async {
          try {
            final body = {...f.toJson(), ...?pin};
            if (factura == null) {
              await service.crear(body);
            } else {
              await service.actualizar(f.idFactura, body);
            }
            ref.invalidate(facturaListProvider);
            return true;
          } catch (_) {
            return false;
          }
        },
      ),
      actions: factura != null && !factura.pagada
          ? [
              TextButton(
                onPressed: () async {
                  final pin = await showPinConfirmDialog(
                    context,
                    title: 'PIN para cancelar',
                  );
                  if (pin == null || !context.mounted) return;
                  if (!await showAppConfirmDialog(
                    context,
                    title: 'Cancelar factura',
                    message: 'Confirma cancelar esta factura?',
                    destructive: true,
                  )) {
                    return;
                  }
                  if (!context.mounted) return;
                  try {
                    await service.eliminar(factura.idFactura, pin);
                    ref.invalidate(facturaListProvider);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      SnackbarUtils.error(context, e.toString());
                    }
                  }
                },
                child: const Text(
                  'Cancelar factura',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ]
          : null,
    );
    if (ok == true && context.mounted) {
      SnackbarUtils.success(context, 'Factura guardada');
    }
  }
}

class _FacturaCard extends StatelessWidget {
  const _FacturaCard({required this.factura, required this.onTap});

  final FacturaModel factura;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = factura.pagada
        ? AppColors.success
        : factura.estado == 'cancelada'
        ? AppColors.error
        : AppColors.warning;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            factura.pagada ? Icons.lock_outline : Icons.receipt_long,
            color: color,
          ),
        ),
        title: Text(
          'Factura #${factura.idFactura}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          'Cita #${factura.citaId} - ${Formatters.dateString(factura.fecha)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.currency(factura.total),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(factura.pagada ? 'Pagada' : factura.estado),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
