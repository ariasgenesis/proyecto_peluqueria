import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../routes/route_names.dart';
import '../../../shared/layouts/admin_shell_layout.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_box.dart';
import '../models/dashboard_admin_model.dart';
import '../providers/dashboard_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(dashboardAdminProvider);

    return AdminShellLayout(
      title: 'Dashboard',
      currentRoute: RouteNames.dashboardAdmin,
      child: asyncData.when(
        loading: () => const _DashboardSkeleton(),
        error: (e, _) =>
            EmptyState(title: 'Error al cargar', subtitle: e.toString()),
        data: (data) => _DashboardContent(
          data: data,
          onRefresh: () => ref.read(dashboardAdminProvider.notifier).refresh(),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.isMobile(context) ? 14 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 220, height: 26),
          const SizedBox(height: 8),
          const SkeletonBox(width: 320, height: 14),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              3,
              (_) => const SizedBox(
                width: 250,
                height: 104,
                child: SkeletonMiniCard(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const SkeletonBox(width: double.infinity, height: 82),
          const SizedBox(height: 18),
          const SkeletonBox(width: double.infinity, height: 420),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data, required this.onRefresh});

  final DashboardAdminModel data;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          isMobile ? 14 : 24,
          isMobile ? 14 : 20,
          isMobile ? 14 : 24,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardHeader(onRefresh: onRefresh),
            const SizedBox(height: 16),
            _KpiStrip(data: data),
            const SizedBox(height: 14),
            const _QuickActionsBar(),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final useTwoColumns = constraints.maxWidth >= 980;
                final agenda = _LiveAgenda(citas: data.citasHoy);
                final side = Column(
                  children: [
                    _RestockStation(productos: data.productosStockBajo),
                    const SizedBox(height: 14),
                    _ActivityFeed(data: data),
                  ],
                );

                if (!useTwoColumns) {
                  return Column(
                    children: [agenda, const SizedBox(height: 14), side],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: agenda),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: side),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Centro operativo',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pulso del dia: citas, caja, abastecimiento y actividad reciente.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Actualizar',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.data});

  final DashboardAdminModel data;

  @override
  Widget build(BuildContext context) {
    final total = data.metricas.citasHoy;
    final pendientes = data.metricas.citasPendientes.clamp(0, total).toInt();
    final gestionadas = (total - pendientes).clamp(0, total).toInt();
    final progress = total == 0 ? 0.0 : gestionadas / total;

    final items = [
      _KpiData(
        label: 'Progreso citas hoy',
        value: '$gestionadas/$total',
        helper: total == 0 ? 'Agenda disponible' : '$pendientes pendientes',
        icon: Icons.event_available_outlined,
        color: AppColors.primary,
        progress: progress,
      ),
      _KpiData(
        label: 'Caja del dia',
        value: Formatters.currency(data.metricas.ingresosHoy),
        helper: 'Ingresos registrados',
        icon: Icons.payments_outlined,
        color: AppColors.success,
      ),
      _KpiData(
        label: 'Clientes',
        value: data.metricas.clientesTotal.toString(),
        helper: 'Total registrado',
        icon: Icons.people_alt_outlined,
        color: AppColors.info,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 112,
          ),
          itemBuilder: (context, index) => _KpiCard(data: items[index]),
        );
      },
    );
  }
}

class _KpiData {
  const _KpiData({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.color,
    this.progress,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;
  final double? progress;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(context),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                if (data.progress != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: data.progress,
                      minHeight: 5,
                      backgroundColor: data.color.withValues(alpha: 0.12),
                      color: data.color,
                    ),
                  )
                else
                  Text(
                    data.helper,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsBar extends StatelessWidget {
  const _QuickActionsBar();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        label: 'Agendar cita',
        icon: Icons.add_task_outlined,
        color: AppColors.primary,
        route: RouteNames.citas,
      ),
      _QuickActionData(
        label: 'Nueva factura',
        icon: Icons.receipt_long_outlined,
        color: AppColors.success,
        route: RouteNames.facturacion,
      ),
      _QuickActionData(
        label: 'Registrar cliente',
        icon: Icons.person_add_alt_1_outlined,
        color: AppColors.info,
        route: RouteNames.clientes,
      ),
      _QuickActionData(
        label: 'Entrada stock',
        icon: Icons.inventory_2_outlined,
        color: AppColors.warning,
        route: RouteNames.inventario,
      ),
    ];

    if (Responsive.isMobile(context)) {
      return SizedBox(
        height: 88,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: actions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            return SizedBox(
              width: 172,
              child: _QuickAction(action: actions[index]),
            );
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _panelDecoration(context),
      child: Row(
        children: actions
            .map(
              (action) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _QuickAction(action: action),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String route;
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.action});

  final _QuickActionData action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.go(action.route),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: action.color.withValues(alpha: 0.13)),
          ),
          child: Row(
            children: [
              Icon(action.icon, color: action.color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveAgenda extends StatelessWidget {
  const _LiveAgenda({required this.citas});

  final List<CitaResumenModel> citas;

  @override
  Widget build(BuildContext context) {
    final sorted = [...citas]..sort((a, b) => a.hora.compareTo(b.hora));

    return Container(
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agenda viva',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Flujo cronologico de citas activas del dia.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _CountPill(count: sorted.length),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (sorted.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 12, 18, 22),
              child: EmptyState(
                title: 'Sin citas hoy',
                subtitle: 'La agenda esta disponible para nuevas reservas.',
                icon: Icons.event_available_outlined,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Column(
                children: sorted.asMap().entries.map((entry) {
                  final isLast = entry.key == sorted.length - 1;
                  return _TimelineAppointment(
                    cita: entry.value,
                    isLast: isLast,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineAppointment extends StatelessWidget {
  const _TimelineAppointment({required this.cita, required this.isLast});

  final CitaResumenModel cita;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final visual = _visualStatus(cita);
    final color = _statusColor(visual);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 62,
            child: Column(
              children: [
                Text(
                  Formatters.timeString(cita.hora),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: isLast
                          ? Colors.transparent
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Material(
                color: color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () => context.go(RouteNames.citas),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: color.withValues(alpha: 0.14)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 560;
                        final details = _AppointmentDetails(cita: cita);
                        final action = _AppointmentAction(cita: cita);

                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              details,
                              const SizedBox(height: 12),
                              action,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: details),
                            const SizedBox(width: 12),
                            action,
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentDetails extends StatelessWidget {
  const _AppointmentDetails({required this.cita});

  final CitaResumenModel cita;

  @override
  Widget build(BuildContext context) {
    final visual = _visualStatus(cita);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _StatusBadge(status: visual),
            if (visual == 'retrasada')
              const _SoftChip(
                label: 'Revisar retraso',
                icon: Icons.warning_amber_outlined,
                color: AppColors.warning,
              ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          cita.clienteDisplay,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Text(
          'Servicio por confirmar',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Icon(
              Icons.content_cut,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Estilista: ${cita.empleadoDisplay}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AppointmentAction extends StatelessWidget {
  const _AppointmentAction({required this.cita});

  final CitaResumenModel cita;

  @override
  Widget build(BuildContext context) {
    final isDone = cita.estado == 'completada';
    final isCanceled = cita.estado == 'cancelada';
    final route = isDone ? RouteNames.facturacion : RouteNames.citas;
    final label = isDone
        ? 'Ver factura'
        : isCanceled
        ? 'Ver tablero'
        : 'Finalizar y cobrar';

    return OutlinedButton.icon(
      onPressed: () => context.go(route),
      icon: Icon(isDone ? Icons.receipt_long_outlined : Icons.arrow_forward),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _RestockStation extends StatelessWidget {
  const _RestockStation({required this.productos});

  final List<ProductoStockBajoModel> productos;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Estacion de reabastecimiento',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                productos.isEmpty
                    ? Icons.check_circle_outline
                    : Icons.inventory_2_outlined,
                color: productos.isEmpty
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (productos.isEmpty)
            const _SuccessState()
          else
            Column(
              children: productos.take(5).map((producto) {
                return _RestockItem(producto: producto);
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _RestockItem extends StatelessWidget {
  const _RestockItem({required this.producto});

  final ProductoStockBajoModel producto;

  @override
  Widget build(BuildContext context) {
    final critical = producto.stock <= (producto.stockMinimo / 2).ceil();
    final color = critical ? AppColors.error : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.13)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.priority_high, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  'Minimo ${producto.stockMinimo}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${producto.stock} restantes',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, color: AppColors.success, size: 30),
          const SizedBox(height: 8),
          Text(
            'Inventario estable',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            'No hay productos criticos.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.data});

  final DashboardAdminModel data;

  @override
  Widget build(BuildContext context) {
    final items = _activityItems(data);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividad reciente',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'Sin actividad reciente.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            Column(
              children: items.take(8).map((item) {
                return _ActivityTile(item: item);
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final _ActivityItemData item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.timeLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count hoy',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItemData {
  const _ActivityItemData({
    required this.title,
    required this.timeLabel,
    required this.icon,
    required this.color,
    this.subtitle,
    this.date,
  });

  final String title;
  final String? subtitle;
  final String timeLabel;
  final IconData icon;
  final Color color;
  final DateTime? date;
}

List<_ActivityItemData> _activityItems(DashboardAdminModel data) {
  final items = <_ActivityItemData>[
    ...data.facturasRecientes.map((factura) {
      final date = DateTime.tryParse(factura.fecha);
      return _ActivityItemData(
        title: 'Factura #${factura.idFactura} creada',
        subtitle: Formatters.currency(factura.total),
        timeLabel: _relativeTime(
          date,
          fallback: Formatters.dateString(factura.fecha),
        ),
        icon: Icons.receipt_long_outlined,
        color: AppColors.success,
        date: date,
      );
    }),
    ...data.movimientosRecientes.map((movimiento) {
      final date = DateTime.tryParse(movimiento.fecha);
      return _ActivityItemData(
        title: movimiento.descripcion,
        subtitle: movimiento.tipo,
        timeLabel: _relativeTime(
          date,
          fallback: Formatters.dateString(movimiento.fecha),
        ),
        icon: Icons.history,
        color: AppColors.primary,
        date: date,
      );
    }),
  ];

  items.sort((a, b) {
    final ad = a.date;
    final bd = b.date;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return bd.compareTo(ad);
  });
  return items;
}

String _visualStatus(CitaResumenModel cita) {
  if (_isLate(cita)) return 'retrasada';
  return cita.estado;
}

bool _isLate(CitaResumenModel cita) {
  if (cita.estado == 'cancelada' || cita.estado == 'completada') return false;
  final time = cita.hora.length == 5 ? '${cita.hora}:00' : cita.hora;
  final dateTime = DateTime.tryParse('${cita.fecha}T$time');
  if (dateTime == null) return false;
  return dateTime.isBefore(DateTime.now());
}

String _statusLabel(String status) {
  switch (status) {
    case 'confirmada':
      return 'Confirmada';
    case 'completada':
      return 'Completada';
    case 'cancelada':
      return 'Cancelada';
    case 'retrasada':
      return 'Retrasada';
    default:
      return 'Pendiente';
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'confirmada':
      return AppColors.info;
    case 'completada':
      return AppColors.success;
    case 'cancelada':
      return AppColors.error;
    case 'retrasada':
      return AppColors.error;
    default:
      return const Color(0xFF8B7D72);
  }
}

String _relativeTime(DateTime? date, {required String fallback}) {
  if (date == null) return fallback;
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Ahora';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
  if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
  return fallback;
}

BoxDecoration _panelDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.045),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );
}
