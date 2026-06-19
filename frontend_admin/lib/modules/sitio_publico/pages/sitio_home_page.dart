import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/route_names.dart';

class SitioHomePage extends StatelessWidget {
  const SitioHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(AppConstants.appName),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.sidebarLight, Color(0xFF2D2640)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.spa, size: 72, color: Colors.white54),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => context.go(RouteNames.login),
                child: const Text('Acceso staff', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Belleza y estética profesional',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Reserva tu cita, conoce nuestros servicios y equipo.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _NavCard(
                      icon: Icons.content_cut,
                      label: 'Servicios',
                      onTap: () => context.go(RouteNames.sitioServicios),
                    ),
                    _NavCard(
                      icon: Icons.groups_outlined,
                      label: 'Equipo',
                      onTap: () => context.go('${RouteNames.sitioInicio}/equipo'),
                    ),
                    _NavCard(
                      icon: Icons.contact_phone_outlined,
                      label: 'Contacto',
                      onTap: () => context.go(RouteNames.sitioContacto),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    minimumSize: const Size(200, 48),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
