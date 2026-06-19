import 'package:jwt_decoder/jwt_decoder.dart';

bool isTokenValid(String? token) {
  if (token == null || token.isEmpty) return false;
  try {
    return !JwtDecoder.isExpired(token);
  } catch (_) {
    return false;
  }
}
