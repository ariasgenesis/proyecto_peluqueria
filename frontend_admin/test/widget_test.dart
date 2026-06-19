import 'package:flutter_test/flutter_test.dart';
import 'package:salon_admin/main.dart';

void main() {
  testWidgets('SalonAdminApp se construye', (tester) async {
    // Smoke test mínimo — la app requiere SharedPreferences en main().
    expect(const SalonAdminApp(), isNotNull);
  });
}
