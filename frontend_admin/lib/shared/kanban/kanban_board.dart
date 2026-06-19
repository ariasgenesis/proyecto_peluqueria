import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/constants/cita_estados.dart';
import '../../core/theme/app_colors.dart';

typedef KanbanCardBuilder<T> = Widget Function(BuildContext context, T item);
typedef KanbanOnMove<T> = Future<void> Function(T item, String newColumnId);

/// Tablero Kanban horizontal estilo Trello/VGen.
class KanbanBoard<T extends Object> extends StatelessWidget {
  const KanbanBoard({
    super.key,
    required this.columns,
    required this.itemsByColumn,
    required this.cardBuilder,
    required this.onMove,
    this.columnWidth = 300,
    this.boardHeight = 520,
    this.readOnly = false,
  });

  final List<KanbanColumnDef> columns;
  final Map<String, List<T>> itemsByColumn;
  final KanbanCardBuilder<T> cardBuilder;
  final KanbanOnMove<T> onMove;
  final double columnWidth;
  final double boardHeight;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: SizedBox(
        height: boardHeight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: columns.map((col) {
              final items = itemsByColumn[col.id] ?? [];
              return _KanbanColumn<T>(
                column: col,
                items: items,
                width: columnWidth,
                columnHeight: boardHeight - 56,
                cardBuilder: cardBuilder,
                onMove: onMove,
                readOnly: readOnly,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _KanbanColumn<T extends Object> extends StatelessWidget {
  const _KanbanColumn({
    required this.column,
    required this.items,
    required this.width,
    required this.columnHeight,
    required this.cardBuilder,
    required this.onMove,
    required this.readOnly,
  });

  final KanbanColumnDef column;
  final List<T> items;
  final double width;
  final double columnHeight;
  final KanbanCardBuilder<T> cardBuilder;
  final KanbanOnMove<T> onMove;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? AppColors.borderDark : AppColors.borderLight)
                    .withValues(alpha: 0.7),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: column.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: column.color.withValues(alpha: 0.42),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    column.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: column.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: column.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DragTarget<T>(
              onWillAcceptWithDetails: (d) => !readOnly,
              onAcceptWithDetails: (d) => onMove(d.data, column.id),
              builder: (context, candidate, rejected) {
                final highlight = candidate.isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: highlight
                        ? column.color.withValues(alpha: 0.10)
                        : (isDark
                              ? AppColors.surfaceDark
                              : Colors.white.withValues(alpha: 0.72)),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: highlight
                          ? column.color.withValues(alpha: 0.58)
                          : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.24 : 0.06,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            'Sin citas',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final card = cardBuilder(context, item);
                            if (readOnly) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: card,
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: LongPressDraggable<T>(
                                data: item,
                                feedback: Material(
                                  color: Colors.transparent,
                                  elevation: 16,
                                  borderRadius: BorderRadius.circular(18),
                                  child: SizedBox(
                                    width: width - 34,
                                    child: card,
                                  ),
                                ),
                                childWhenDragging: AnimatedOpacity(
                                  opacity: 0.28,
                                  duration: const Duration(milliseconds: 150),
                                  child: card,
                                ),
                                child: AnimatedScale(
                                  scale: highlight ? 0.985 : 1,
                                  duration: const Duration(milliseconds: 160),
                                  child: card,
                                ),
                              ),
                            );
                          },
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
