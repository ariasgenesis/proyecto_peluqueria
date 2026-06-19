import '../../../core/utils/validators.dart';

/// Lógica de validación del formulario de login (sin estado UI).
class LoginController {
  LoginController._();

  static String? validateUsername(String? value) => Validators.username(value);
  static String? validatePassword(String? value) => Validators.password(value);
}
