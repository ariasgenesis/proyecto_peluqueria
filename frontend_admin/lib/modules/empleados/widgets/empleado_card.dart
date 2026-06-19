import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/empleado_model.dart';

class EmpleadoCard extends StatelessWidget {
  const EmpleadoCard({
    super.key,
    required this.empleado,
    required this.onEdit,
    required this.onDelete,
  });

  final EmpleadoModel empleado;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(empleado.nombre.substring(0, 1).toUpperCase()),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      empleado.nombreCompleto,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      const PopupMenuItem(value: 'del', child: Text('Eliminar')),
                    ],
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'del') onDelete();
                    },
                  ),
                ],
              ),
              const Spacer(),
              if (empleado.cargo != null)
                Text(empleado.cargo!, style: Theme.of(context).textTheme.bodySmall),
              if (empleado.documento != null)
                Text(
                  'Doc: ${empleado.documento}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              if (empleado.telefono != null) ...[
                const SizedBox(height: 4),
                Text(empleado.telefono!, style: Theme.of(context).textTheme.labelSmall),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}
