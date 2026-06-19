import 'package:flutter/material.dart';

class SnackbarUtils {
  SnackbarUtils._();

  static void success(BuildContext context, String message) {
    _show(context, message, Icons.check_circle_outline, Colors.green.shade700);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, Icons.error_outline, Colors.red.shade700);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, Icons.info_outline, null);
  }

  static void _show(
    BuildContext context,
    String message,
    IconData icon,
    Color? accent,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: accent ?? Theme.of(context).colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
