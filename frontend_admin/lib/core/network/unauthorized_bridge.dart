import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puente para desacoplar Dio del módulo auth (evita dependencia circular).
final unauthorizedBridgeProvider = Provider<UnauthorizedBridge>(
  (ref) => UnauthorizedBridge(),
);

class UnauthorizedBridge {
  void Function()? onUnauthorized;

  void notify() => onUnauthorized?.call();
}
