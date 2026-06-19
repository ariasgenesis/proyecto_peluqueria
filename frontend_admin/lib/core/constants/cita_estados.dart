import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Columnas Kanban alineadas con estados persistidos de citas.
class CitaEstados {
  CitaEstados._();

  static const List<KanbanColumnDef> kanbanColumns = [
    KanbanColumnDef(id: 'pendiente', label: 'Pendiente', color: AppColors.info),
    KanbanColumnDef(
      id: 'confirmada',
      label: 'Confirmada',
      color: AppColors.primary,
    ),
    KanbanColumnDef(
      id: 'completada',
      label: 'Finalizada',
      color: AppColors.success,
    ),
    KanbanColumnDef(
      id: 'cancelada',
      label: 'Cancelada',
      color: AppColors.error,
    ),
  ];

  static Color colorFor(String estado) {
    return kanbanColumns
        .firstWhere((c) => c.id == estado, orElse: () => kanbanColumns.first)
        .color;
  }

  static String labelFor(String estado) {
    return kanbanColumns
        .firstWhere((c) => c.id == estado, orElse: () => kanbanColumns.first)
        .label;
  }
}

class KanbanColumnDef {
  const KanbanColumnDef({
    required this.id,
    required this.label,
    required this.color,
  });

  final String id;
  final String label;
  final Color color;
}
