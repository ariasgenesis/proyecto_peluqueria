import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/auth/models/usuario_model.dart';
import '../constants/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'token_storage.dart';

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage(ref.watch(sharedPreferencesProvider));
});

class SessionStorage {
  SessionStorage(this._prefs);

  final SharedPreferences _prefs;

  Future<void> saveSession({
    required String token,
    required UsuarioModel usuario,
  }) async {
    await _prefs.setString(StorageKeys.accessToken, token);
    await _prefs.setString(
      StorageKeys.usuarioJson,
      jsonEncode(usuario.toJson()),
    );
  }

  String? getToken() => _prefs.getString(StorageKeys.accessToken);

  UsuarioModel? getUsuario() {
    final raw = _prefs.getString(StorageKeys.usuarioJson);
    if (raw == null) return null;
    try {
      return UsuarioModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    await _prefs.remove(StorageKeys.accessToken);
    await _prefs.remove(StorageKeys.usuarioJson);
  }
}
