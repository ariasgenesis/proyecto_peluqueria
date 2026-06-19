import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/cita_estados.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/dialogs/app_modal_sheet.dart';
import '../../../shared/kanban/kanban_board.dart';
import '../../../shared/layouts/admin_shell_layout.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../controllers/cita_controller.dart';
import '../models/cita_model.dart';
import '../widgets/cita_form_modal.dart';
import '../widgets/cita_kanban_card.dart';

/// Vista principal de citas — tablero Kanban integrado (no módulo separado).
class CitaKanbanPage extends ConsumerWidget {
  const CitaKanbanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(citaBoardControllerProvider);
    final ctrl = ref.read(citaBoardControllerProvider.notifier);
    final height = MediaQuery.sizeOf(context).height - (Responsive.isMobile(context) ? 140 : 120);

    return AdminShellLayout(
      title: 'Citas',
      currentRoute: '/citas',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text(
                  'Tablero operativo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Actualizar',
                  onPressed: ctrl.cargar,
                  icon: const Icon(Icons.refresh),
                ),
                FilledButton.icon(
                  onPressed: () => _openModal(context, ref),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Nueva cita'),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const AppLoading(message: 'Cargando citas...')
                : state.error != null
                    ? EmptyState(title: state.error!, icon: Icons.error_outline)
                    : KanbanBoard<CitaModel>(
                        columns: CitaEstados.kanbanColumns,
                        itemsByColumn: state.porColumna,
                        boardHeight: height,
                        columnWidth: Responsive.isMobile(context) ? 260 : 300,
                        onMove: (cita, col) async {
                          final ok = await ctrl.moverEstado(cita, col);
                          if (context.mounted) {
                            if (ok) {
                              SnackbarUtils.success(context, 'Estado actualizado');
                            } else {
                              SnackbarUtils.error(context, 'No se pudo mover la cita');
                            }
                          }
                          return;
                        },
                        cardBuilder: (ctx, cita) => CitaKanbanCard(
                          cita: cita,
                          onTap: () => _openModal(context, ref, cita: cita),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _openModal(BuildContext context, WidgetRef ref, {CitaModel? cita}) async {
    final ctrl = ref.read(citaBoardControllerProvider.notifier);
    await showAppModal(
      context,
      title: cita == null ? 'Nueva cita' : 'Editar cita #${cita.idCita}',
      child: CitaFormModal(
        cita: cita,
        onSubmit: (c) => ctrl.guardar(c, esNuevo: cita == null),
      ),
    );
  }
}
