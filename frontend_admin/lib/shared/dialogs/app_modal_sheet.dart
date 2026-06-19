import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/utils/responsive.dart';

/// Modal flotante estilo SaaS para CRUD sin cambiar de pagina.
Future<T?> showAppModal<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required Widget child,
  bool isDestructive = false,
  List<Widget>? actions,
}) {
  final isMobile = Responsive.isMobile(context);
  final width = MediaQuery.sizeOf(context).width;
  final height = MediaQuery.sizeOf(context).height;
  final modalWidth = isMobile ? width : (width * 0.42).clamp(420.0, 620.0);
  final modalHeight = isMobile ? height * 0.92 : height * 0.88;

  if (isMobile) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          MediaQuery.viewInsetsOf(ctx).bottom + 12,
        ),
        child: _ModalShell(
          height: modalHeight,
          child: _ModalBody(
            title: title,
            subtitle: subtitle,
            actions: actions,
            isDestructive: isDestructive,
            child: child,
          ),
        ),
      ),
    );
  }

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (ctx, _, _) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _ModalShell(
            width: modalWidth,
            height: modalHeight,
            child: _ModalBody(
              title: title,
              subtitle: subtitle,
              actions: actions,
              isDestructive: isDestructive,
              child: child,
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

class _ModalShell extends StatelessWidget {
  const _ModalShell({required this.child, this.width, required this.height});

  final Widget child;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Theme.of(
              context,
            ).dividerColor.withValues(alpha: isDark ? 0.8 : 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
              blurRadius: 42,
              offset: const Offset(0, 22),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    ).animate().fadeIn(duration: 180.ms, curve: Curves.easeOut);
  }
}

class _ModalBody extends StatelessWidget {
  const _ModalBody({
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.isDestructive = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 20, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 4, 28, 28),
            child: child,
          ),
        ),
        if (actions != null) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 10,
              children: actions!,
            ),
          ),
        ],
      ],
    );
  }
}
