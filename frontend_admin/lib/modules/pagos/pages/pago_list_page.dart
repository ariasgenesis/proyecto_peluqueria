import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/dialogs/app_modal_sheet.dart';
import '../../../shared/layouts/admin_shell_layout.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/pago_model.dart';
import '../services/pago_service.dart';
import '../widgets/pago_form_modal.dart';

final pagoListProvider = FutureProvider<List<PagoModel>>((ref) async {
  final res = await ref.watch(pagoServiceProvider).listar();
  return res.data;
});

class PagoListPage extends ConsumerWidget {
  const PagoListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pagoListProvider);

    return AdminShellLayout(
      title: 'Pagos',
      currentRoute: '/pagos',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _open(context, ref),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Registrar pago'),
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const AppLoading(),
              error: (e, _) => EmptyState(title: e.toString(), icon: Icons.cloud_off),
              data: (items) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final p = items[i];
                  return Card(
                    child: ListTile(
                      title: Text('Pago #${p.idPago} · Factura #${p.facturaId}'),
                      subtitle: Text('${p.metodo} · ${p.estado} · ${Formatters.dateString(p.fecha)}'),
                      trailing: Text(Formatters.currency(p.monto)),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final service = ref.read(pagoServiceProvider);
    await showAppModal(
      context,
      title: 'Registrar pago',
      child: PagoFormModal(
        onSubmit: (p) async {
          try {
            await service.crear(p.toJson());
            ref.invalidate(pagoListProvider);
            return true;
          } catch (_) {
            return false;
          }
        },
      ),
    );
    if (context.mounted) SnackbarUtils.success(context, 'Pago registrado');
  }
}
