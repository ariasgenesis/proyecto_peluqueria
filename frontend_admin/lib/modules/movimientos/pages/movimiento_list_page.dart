import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/layouts/admin_shell_layout.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/movimiento_model.dart';
import '../services/movimiento_service.dart';

final movimientoListProvider = FutureProvider<List<MovimientoModel>>((ref) async {
  final res = await ref.watch(movimientoServiceProvider).listar(perPage: 100);
  return res.data;
});

class MovimientoListPage extends ConsumerWidget {
  const MovimientoListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(movimientoListProvider);

    return AdminShellLayout(
      title: 'Movimientos',
      currentRoute: '/movimientos',
      child: async.when(
        loading: () => const AppLoading(message: 'Cargando historial...'),
        error: (e, _) => EmptyState(title: e.toString(), icon: Icons.cloud_off),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final m = items[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(m.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${m.tipo} · Usuario #${m.usuarioId} · ${Formatters.dateString(m.fecha)}',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
