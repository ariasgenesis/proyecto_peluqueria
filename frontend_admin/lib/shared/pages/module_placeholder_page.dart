import 'package:flutter/material.dart';

import '../layouts/admin_shell_layout.dart';

/// Pantalla temporal hasta implementar cada módulo CRUD.
class ModulePlaceholderPage extends StatelessWidget {
  const ModulePlaceholderPage({
    super.key,
    required this.title,
    required this.route,
    this.description,
  });

  final String title;
  final String route;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return AdminShellLayout(
      title: title,
      currentRoute: route,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                description ?? 'Módulo en desarrollo — estructura lista para CRUD.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
