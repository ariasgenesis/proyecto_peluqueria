import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/dialogs/app_confirm_dialog.dart';
import '../../../shared/dialogs/app_modal_sheet.dart';
import '../../../shared/layouts/admin_shell_layout.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../controllers/empleado_controller.dart';
import '../models/empleado_model.dart';
import '../widgets/empleado_card.dart';
import '../widgets/empleado_form_modal.dart';

class EmpleadoListPage extends ConsumerWidget {
  const EmpleadoListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(empleadoListControllerProvider);
    final ctrl = ref.read(empleadoListControllerProvider.notifier);

    return AdminShellLayout(
      title: 'Empleados',
      currentRoute: '/empleados',
      child: Column(
        children: [
          _Toolbar(
            search: state.search,
            onSearch: (q) => ctrl.cargar(search: q),
            onAdd: () => _openForm(context, ref),
          ),
          Expanded(
            child: state.isLoading
                ? const AppLoading(message: 'Cargando empleados...')
                : state.error != null
                    ? EmptyState(title: state.error!, icon: Icons.error_outline)
                    : state.items.isEmpty
                        ? EmptyState(
                            title: 'Sin empleados',
                            subtitle: 'Registra el primer empleado',
                            icon: Icons.badge_outlined,
                          )
                        : _Grid(
                            items: state.items,
                            onEdit: (e) => _openForm(context, ref, empleado: e),
                            onDelete: (e) => _delete(context, ref, e),
                          ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    EmpleadoModel? empleado,
  }) async {
    final ctrl = ref.read(empleadoListControllerProvider.notifier);
    final ok = await showAppModal<bool>(
      context,
      title: empleado == null ? 'Nuevo empleado' : 'Editar empleado',
      child: EmpleadoFormModal(
        empleado: empleado,
        onSubmit: (model, pin) => ctrl.guardar(model, pin: pin, esNuevo: empleado == null),
      ),
    );
    if (ok == true && context.mounted) {
      SnackbarUtils.success(context, 'Empleado guardado');
    } else if (context.mounted) {
      final err = ref.read(empleadoListControllerProvider).error;
      if (err != null) SnackbarUtils.error(context, err);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, EmpleadoModel e) async {
    final confirm = await showAppConfirmDialog(
      context,
      title: 'Eliminar empleado',
      message: '¿Eliminar a ${e.nombreCompleto}?',
      destructive: true,
    );
    if (!confirm || !context.mounted) return;
    final ok = await ref.read(empleadoListControllerProvider.notifier).eliminar(e.idEmpleado);
    if (context.mounted) {
      SnackbarUtils.success(context, ok ? 'Empleado eliminado' : 'No se pudo eliminar');
    }
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.search, required this.onSearch, required this.onAdd});
  final String search;
  final ValueChanged<String> onSearch;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar empleado...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onSubmitted: onSearch,
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Nuevo'),
          ),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.items, required this.onEdit, required this.onDelete});
  final List<EmpleadoModel> items;
  final void Function(EmpleadoModel) onEdit;
  final void Function(EmpleadoModel) onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 1200 ? 4 : (c.maxWidth > 800 ? 3 : (c.maxWidth > 500 ? 2 : 1));
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => EmpleadoCard(
            empleado: items[i],
            onEdit: () => onEdit(items[i]),
            onDelete: () => onDelete(items[i]),
          ),
        );
      },
    );
  }
}
