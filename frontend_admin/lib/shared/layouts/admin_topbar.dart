import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_provider.dart';
import '../../modules/auth/models/usuario_model.dart';

class AdminTopbar extends ConsumerWidget implements PreferredSizeWidget {
  const AdminTopbar({
    super.key,
    required this.title,
    this.usuario,
    this.onLogout,
    this.onMenuTap,
  });

  final String title;
  final UsuarioModel? usuario;
  final VoidCallback? onLogout;
  final VoidCallback? onMenuTap;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            if (onMenuTap != null)
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: onMenuTap,
              ),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Cambiar tema',
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            ),
            if (usuario != null) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  usuario!.username.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario!.username,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    usuario!.rol.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
            if (onLogout != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: onLogout,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
