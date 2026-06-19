class Validators {
  Validators._();

  static String? required(
    String? value, {
    String field = 'Este campo',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$field es requerido';
    }
    return null;
  }

  static String? username(String? value) {
    final base = required(value, field: 'Usuario');

    if (base != null) return base;

    if (value!.trim().length < 3) {
      return 'Usuario debe tener al menos 3 caracteres';
    }

    return null;
  }

  static String? password(String? value) {
    final base = required(
      value,
      field: 'Contraseña',
    );

    if (base != null) return base;

    if (value!.length < 4) {
      return 'Contraseña demasiado corta';
    }

    return null;
  }

  // =========================
  // NOMBRE
  // =========================

  static String? nombre(String? value) {
    final base = required(
      value,
      field: 'Nombre',
    );

    if (base != null) return base;

    final regex = RegExp(
      r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$',
    );

    if (!regex.hasMatch(value!.trim())) {
      return 'Solo letras';
    }

    return null;
  }

  // =========================
  // DOCUMENTO
  // =========================

  static String? documento(String? value) {
    final base = required(
      value,
      field: 'Documento',
    );

    if (base != null) return base;

    if (value!.trim().length < 6) {
      return 'Documento inválido';
    }

    return null;
  }

  // =========================
  // TELÉFONO OPCIONAL
  // =========================

  static String? telefonoOpcional(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return null;
    }

    if (value.trim().length < 7) {
      return 'Teléfono inválido';
    }

    return null;
  }

  // =========================
  // PIN
  // =========================

  static String? pin(
    String? value, {
    bool requerido = false,
  }) {
    if (requerido &&
        (value == null || value.isEmpty)) {
      return 'PIN requerido';
    }

    if (value != null &&
        value.isNotEmpty &&
        value.length != 4) {
      return 'Debe tener 4 dígitos';
    }

    return null;
  }
}