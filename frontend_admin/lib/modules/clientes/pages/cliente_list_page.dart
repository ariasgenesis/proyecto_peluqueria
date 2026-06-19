import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/dialogs/app_confirm_dialog.dart';
import '../../../shared/dialogs/app_modal_sheet.dart';
import '../../../shared/layouts/admin_shell_layout.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../controllers/cliente_controller.dart';
import '../models/cliente_model.dart';
import '../widgets/cliente_form_modal.dart';

class ClienteListPage extends ConsumerWidget {
  const ClienteListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clienteListControllerProvider);
    final ctrl = ref.read(clienteListControllerProvider.notifier);

    return AdminShellLayout(
      title: 'Clientes',
      currentRoute: '/clientes',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Búsqueda rápida...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onSubmitted: (q) => ctrl.cargar(search: q),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _openForm(context, ref),
                  icon: const Icon(Icons.person_add_outlined, size: 20),
                  label: const Text('Nuevo'),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const AppLoading()
                : state.items.isEmpty
                    ? const EmptyState(title: 'Sin clientes', icon: Icons.people_outline)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.items.length,
                        itemBuilder: (_, i) {
                          final c = state.items[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(child: Text(c.nombre[0].toUpperCase())),
                              title: Text(c.nombreCompleto),
                              subtitle: Text(
                                [c.telefono, c.direccion].whereType<String>().join(' · '),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _openForm(context, ref, cliente: c),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _delete(context, ref, c),
                                  ),
                                ],
                              ),
                              onTap: () => _openForm(context, ref, cliente: c),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref, {ClienteModel? cliente}) async {
    final ctrl = ref.read(clienteListControllerProvider.notifier);
    final ok = await showAppModal<bool>(
      context,
      title: cliente == null ? 'Nuevo cliente' : 'Editar cliente',
      child: ClienteFormModal(
        cliente: cliente,
        onSubmit: (c) => ctrl.guardar(c, esNuevo: cliente == null),
      ),
    );
    if (ok == true && context.mounted) {
      SnackbarUtils.success(context, 'Cliente guardado');
    } else if (context.mounted) {
      final err = ref.read(clienteListControllerProvider).error;
      if (err != null) SnackbarUtils.error(context, err);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, ClienteModel c) async {
    if (!await showAppConfirmDialog(context, title: 'Eliminar', message: '¿Eliminar ${c.nombreCompleto}?', destructive: true)) return;
    final ok = await ref.read(clienteListControllerProvider.notifier).eliminar(c.idCliente);
    if (context.mounted) SnackbarUtils.success(context, ok ? 'Eliminado' : 'Error');
  }
}
