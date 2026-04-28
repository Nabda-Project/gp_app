import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api/dio_client.dart';

/// Manages the back-end JWT token using encrypted secure storage.
class TokenService {
  TokenService._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'backend_jwt_token';
  static const _emailKey = 'backend_email';
  static const _passwordKey = 'backend_password';

  // ─── JWT Token ───

  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      DioClient.resetForceLogoutGuard();
    } catch (e) {
      await _storage.deleteAll();
      await _storage.write(key: _tokenKey, value: token);
      DioClient.resetForceLogoutGuard();
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      await _storage.deleteAll();
      return null;
    }
  }

  static Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      await _storage.deleteAll();
    }
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ─── Stored Credentials (for auto-re-login when JWT expires) ───

  static Future<void> saveCredentials(String email, String password) async {
    try {
      await _storage.write(key: _emailKey, value: email);
      await _storage.write(key: _passwordKey, value: password);
    } catch (e) {
      await _storage.deleteAll();
      await _storage.write(key: _emailKey, value: email);
      await _storage.write(key: _passwordKey, value: password);
    }
  }

  static Future<Map<String, String>?> getCredentials() async {
    try {
      final email = await _storage.read(key: _emailKey);
      final password = await _storage.read(key: _passwordKey);
      if (email != null && password != null) {
        return {'email': email, 'password': password};
      }
    } catch (e) {
      await _storage.deleteAll();
    }
    return null;
  }

  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
