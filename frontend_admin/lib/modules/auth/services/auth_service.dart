import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_session_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiClientProvider));
});

class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  Future<AuthSessionModel> login({
    required String username,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {
        'username': username.trim(),
        'password': password,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );

    return AuthSessionModel.fromJson(response.data!);
  }
}
