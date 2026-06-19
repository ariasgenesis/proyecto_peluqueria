import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../routes/route_names.dart';
import '../../../shared/cards/cita_mini_card.dart';
import '../../../shared/cards/section_card.dart';
import '../../../shared/layouts/admin_shell_layout.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/horizontal_carousel.dart';
import '../providers/dashboard_provider.dart';

class EmpleadoDashboardPage extends ConsumerWidget {
  const EmpleadoDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(dashboardEmpleadoProvider);

    return AdminShellLayout(
      title: 'Mi agenda',
      currentRoute: RouteNames.dashboardEmpleado,
      child: asyncData.when(
        loading: () => const AppLoading(message: 'Cargando agenda...'),
        error: (e, _) => EmptyState(title: e.toString()),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.read(dashboardEmpleadoProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu día',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                HorizontalCarousel(
                  height: 148,
                  title: 'Citas del día',
                  trailing: TextButton(
                    onPressed: () => context.go(RouteNames.citas),
                    child: const Text('Tablero'),
                  ),
                  emptyWidget: const EmptyState(
                    title: 'Sin citas hoy',
                    icon: Icons.event_available,
                  ),
                  children: data.citasDia.asMap().entries.map((e) {
                    final c = e.value;
                    return CitaMiniCard(
                      clienteNombre: c.clienteDisplay,
                      hora: c.hora,
                      empleadoNombre: 'Mi agenda',
                      estado: c.estado,
                      delayMs: e.key * 40,
                      onTap: () => context.go(RouteNames.citas),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                HorizontalCarousel(
                  height: 148,
                  title: 'Próximas citas',
                  children: data.proximasCitas.asMap().entries.map((e) {
                    final c = e.value;
                    return CitaMiniCard(
                      clienteNombre: c.clienteDisplay,
                      hora: c.hora,
                      empleadoNombre: Formatters.dateString(c.fecha),
                      estado: c.estado,
                      delayMs: e.key * 40,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SectionCard(
                  title: 'Actividad reciente',
                  icon: Icons.timeline,
                  child: data.actividadReciente.isEmpty
                      ? const Text('Sin actividad')
                      : Column(
                          children: data.actividadReciente.map((a) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(a.descripcion, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(a.tipo),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
