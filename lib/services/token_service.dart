import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the back-end JWT token using encrypted secure storage.
class TokenService {
  TokenService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  static const _tokenKey = 'backend_jwt_token';
  static const _emailKey = 'backend_email';
  static const _passwordKey = 'backend_password';

  // ─── JWT Token ───

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ─── Stored Credentials (for auto-re-login when JWT expires) ───

  static Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
  }

  static Future<Map<String, String>?> getCredentials() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
