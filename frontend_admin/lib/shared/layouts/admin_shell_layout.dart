import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/responsive.dart';
import '../../modules/auth/providers/auth_provider.dart';
import '../../routes/route_names.dart';
import 'admin_sidebar.dart';
import 'admin_topbar.dart';

class AdminShellLayout extends ConsumerStatefulWidget {
  const AdminShellLayout({
    super.key,
    required this.title,
    required this.child,
    this.currentRoute = '',
  });

  final String title;
  final Widget child;
  final String currentRoute;

  @override
  ConsumerState<AdminShellLayout> createState() => _AdminShellLayoutState();
}

class _AdminShellLayoutState extends ConsumerState<AdminShellLayout> {
  bool _sidebarCollapsed = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(currentUsuarioProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final isMobile = Responsive.isMobile(context);

    Future<void> logout() async {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }

    final dashboardRoute = isAdmin
        ? RouteNames.dashboardAdmin
        : RouteNames.dashboardEmpleado;

    final sidebar = AdminSidebar(
      collapsed: _sidebarCollapsed && !isMobile,
      currentRoute: widget.currentRoute,
      isAdmin: isAdmin,
      dashboardRoute: dashboardRoute,
      onToggle: isMobile
          ? null
          : () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
    );

    return Scaffold(
      key: _scaffoldKey,
      body: Row(
        children: [
          if (!isMobile) sidebar,
          Expanded(
            child: Column(
              children: [
                AdminTopbar(
                  title: widget.title,
                  usuario: usuario,
                  onLogout: logout,
                  onMenuTap: isMobile
                      ? () => _scaffoldKey.currentState?.openDrawer()
                      : null,
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
      drawer: isMobile
          ? Drawer(child: sidebar)
          : null,
    );
  }
}
