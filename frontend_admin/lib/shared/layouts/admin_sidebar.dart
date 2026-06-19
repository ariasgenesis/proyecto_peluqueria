import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/route_names.dart';

class SidebarItem {
  const SidebarItem({
    required this.label,
    required this.icon,
    required this.route,
    this.adminOnly = false,
  });

  final String label;
  final IconData icon;
  final String route;
  final bool adminOnly;
}

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.collapsed,
    required this.currentRoute,
    required this.isAdmin,
    required this.dashboardRoute,
    this.onToggle,
  });

  final bool collapsed;
  final String currentRoute;
  final bool isAdmin;
  final String dashboardRoute;
  final VoidCallback? onToggle;

  List<SidebarItem> get items => [
    SidebarItem(label: 'Dashboard', icon: Icons.dashboard_outlined, route: dashboardRoute),
    SidebarItem(label: 'Empleados', icon: Icons.badge_outlined, route: RouteNames.empleados, adminOnly: true),
    SidebarItem(label: 'Clientes', icon: Icons.people_outline, route: RouteNames.clientes),
    SidebarItem(label: 'Horarios', icon: Icons.calendar_month_outlined, route: RouteNames.horarios),
    SidebarItem(label: 'Servicios', icon: Icons.content_cut_outlined, route: RouteNames.servicios),
    SidebarItem(label: 'Inventario', icon: Icons.warehouse_outlined, route: RouteNames.inventario, adminOnly: true),
    SidebarItem(label: 'Citas', icon: Icons.view_kanban_outlined, route: RouteNames.citas),
    SidebarItem(label: 'Facturación', icon: Icons.receipt_long_outlined, route: RouteNames.facturacion),
    SidebarItem(label: 'Pagos', icon: Icons.payments_outlined, route: RouteNames.pagos),
    SidebarItem(label: 'Movimientos', icon: Icons.history_outlined, route: RouteNames.movimientos, adminOnly: true),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.sidebarDark : AppColors.sidebarLight;
    final textColor = isDark ? AppColors.sidebarTextDark : AppColors.sidebarTextLight;

    final visibleItems = items.where((i) => !i.adminOnly || isAdmin).toList();

    return Container(
      width: collapsed ? AppConstants.sidebarCollapsedWidth : AppConstants.sidebarExpandedWidth,
      color: bg,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.spa, color: AppColors.primary, size: 28),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppConstants.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (onToggle != null)
                  IconButton(
                    icon: Icon(
                      collapsed ? Icons.chevron_right : Icons.chevron_left,
                      color: textColor,
                      size: 20,
                    ),
                    onPressed: onToggle,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: visibleItems.length,
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                final selected = currentRoute == item.route ||
                    currentRoute.startsWith('${item.route}/');

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Material(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => context.go(item.route),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: collapsed ? 12 : 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: selected ? AppColors.primary : textColor,
                              size: 22,
                            ),
                            if (!collapsed) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    color: selected ? Colors.white : textColor,
                                    fontWeight:
                                        selected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
