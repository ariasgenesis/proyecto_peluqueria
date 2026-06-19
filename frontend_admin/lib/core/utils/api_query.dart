/// Construye query parameters omitiendo entradas con valor null.
///
/// Preferir este helper o `'clave': ?valor` en mapas literales
/// (lint use_null_aware_elements). Evitar `if (x != null) 'clave': x`.
Map<String, dynamic> apiQuery(Map<String, Object?> params) {
  return {
    for (final entry in params.entries)
      if (entry.value != null) entry.key: entry.value!,
  };
}
