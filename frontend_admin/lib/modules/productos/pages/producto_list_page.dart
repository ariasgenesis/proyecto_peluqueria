import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../routes/route_names.dart';
import '../../../shared/dialogs/app_modal_sheet.dart';
import '../../../shared/layouts/admin_shell_layout.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../controllers/producto_controller.dart';
import '../models/producto_model.dart';
import '../widgets/producto_form_modal.dart';

class ProductoListPage extends ConsumerWidget {
  const ProductoListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productoListControllerProvider);

    return AdminShellLayout(
      title: 'Productos',
      currentRoute: RouteNames.productos,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => context.go(RouteNames.inventario),
                  icon: const Icon(Icons.warehouse_outlined),
                  label: const Text('Vista inventario'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _openForm(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const AppLoading(),
              error: (e, _) => EmptyState(
                title: 'Error de conexión',
                subtitle: '$e\nAPI: verifique backend en puerto 4000',
                icon: Icons.cloud_off,
              ),
              data: (items) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final p = items[i];
                  return Card(
                    child: ListTile(
                      title: Text(p.nombre),
                      subtitle: Text(
                        '${Formatters.currency(p.precio)} · Stock ${p.stock} (mín ${p.stockMinimo})',
                      ),
                      leading: Icon(
                        p.stockBajo ? Icons.warning_amber : Icons.inventory_2,
                        color: p.stockBajo ? AppColors.warning : null,
                      ),
                      onTap: () => _openForm(context, ref, producto: p),
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

  Future<void> _openForm(BuildContext context, WidgetRef ref, {ProductoModel? producto}) async {
    final ctrl = ref.read(productoListControllerProvider.notifier);
    await showAppModal(
      context,
      title: producto == null ? 'Nuevo producto' : 'Editar producto',
      child: ProductoFormModal(
        producto: producto,
        onSubmit: (p) => ctrl.guardar(p, esNuevo: producto == null),
      ),
    );
    if (context.mounted) SnackbarUtils.success(context, 'Guardado');
  }
}
