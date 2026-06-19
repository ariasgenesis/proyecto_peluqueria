import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences debe inicializarse en main()');
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(sharedPreferencesProvider));
});

class TokenStorage {
  TokenStorage(this._prefs);

  final SharedPreferences _prefs;

  String? getToken() => _prefs.getString(StorageKeys.accessToken);

  Future<void> saveToken(String token) async {
    await _prefs.setString(StorageKeys.accessToken, token);
  }

  Future<void> clearToken() async {
    await _prefs.remove(StorageKeys.accessToken);
  }
}
