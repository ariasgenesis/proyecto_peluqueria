import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/dialogs/app_modal_sheet.dart';
import '../../../shared/layouts/admin_shell_layout.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../controllers/servicio_controller.dart';
import '../models/servicio_model.dart';
import '../widgets/servicio_form_modal.dart';

class ServicioListPage extends ConsumerWidget {
  const ServicioListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(servicioListControllerProvider);
    final ctrl = ref.read(servicioListControllerProvider.notifier);
    final isAdmin = ref.watch(isAdminProvider);

    return AdminShellLayout(
      title: 'Servicios',
      currentRoute: '/servicios',
      child: async.when(
        loading: () => const AppLoading(),
        error: (e, _) => EmptyState(title: e.toString()),
        data: (items) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isAdmin
                          ? 'Gestiona servicios activos e inactivos sin perder historial.'
                          : 'Consulta el catalogo de servicios. La edicion esta reservada para administradores.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (isAdmin)
                    FilledButton.icon(
                      onPressed: () => _open(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Nuevo servicio'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const EmptyState(
                      title: 'Sin servicios',
                      icon: Icons.content_cut,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final s = items[i];
                        return _ServicioCard(
                          servicio: s,
                          isAdmin: isAdmin,
                          onTap: isAdmin
                              ? () => _open(context, ref, servicio: s)
                              : null,
                          onToggle: isAdmin
                              ? (_) => ctrl.toggleEstado(s)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref, {
    ServicioModel? servicio,
  }) async {
    final ctrl = ref.read(servicioListControllerProvider.notifier);
    final ok = await showAppModal<bool>(
      context,
      title: servicio == null ? 'Nuevo servicio' : 'Editar servicio',
      subtitle:
          'Mantiene el catalogo administrativo visible incluso cuando un servicio esta inactivo.',
      child: ServicioFormModal(
        servicio: servicio,
        onSubmit: (s) => ctrl.guardar(s, esNuevo: servicio == null),
      ),
    );
    if (ok == true && context.mounted) {
      SnackbarUtils.success(context, 'Servicio guardado');
    }
  }
}

class _ServicioCard extends StatelessWidget {
  const _ServicioCard({
    required this.servicio,
    required this.isAdmin,
    this.onTap,
    this.onToggle,
  });

  final ServicioModel servicio;
  final bool isAdmin;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final inactive = !servicio.activo;
    return Opacity(
      opacity: inactive ? 0.72 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (inactive ? AppColors.warning : AppColors.primary)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              inactive ? Icons.block : Icons.spa_outlined,
              color: inactive ? AppColors.warning : AppColors.primary,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  servicio.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    decoration: inactive ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(inactive ? 'Inactivo' : 'Activo'),
                backgroundColor:
                    (inactive ? AppColors.warning : AppColors.success)
                        .withValues(alpha: 0.12),
                side: BorderSide.none,
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${servicio.duracion} min · ${Formatters.currency(servicio.precio)}',
            ),
          ),
          trailing: isAdmin
              ? Switch(value: servicio.activo, onChanged: onToggle)
              : const Icon(Icons.lock_outline, size: 18),
          onTap: onTap,
        ),
      ),
    );
  }
}
