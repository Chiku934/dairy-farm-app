import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryFallback = {};
  bool _useFallback = false;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyUserSession = 'auth_user_session';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      if (!_useFallback) {
        await _storage.write(key: _keyAccessToken, value: accessToken);
        await _storage.write(key: _keyRefreshToken, value: refreshToken);
        return;
      }
    } catch (_) {
      _useFallback = true;
    }
    _memoryFallback[_keyAccessToken] = accessToken;
    _memoryFallback[_keyRefreshToken] = refreshToken;
  }

  Future<String?> getAccessToken() async {
    try {
      if (!_useFallback) {
        return await _storage.read(key: _keyAccessToken);
      }
    } catch (_) {
      _useFallback = true;
    }
    return _memoryFallback[_keyAccessToken];
  }

  Future<String?> getRefreshToken() async {
    try {
      if (!_useFallback) {
        return await _storage.read(key: _keyRefreshToken);
      }
    } catch (_) {
      _useFallback = true;
    }
    return _memoryFallback[_keyRefreshToken];
  }

  Future<void> saveUserSession(String sessionJson) async {
    try {
      if (!_useFallback) {
        await _storage.write(key: _keyUserSession, value: sessionJson);
        return;
      }
    } catch (_) {
      _useFallback = true;
    }
    _memoryFallback[_keyUserSession] = sessionJson;
  }

  Future<String?> getUserSession() async {
    try {
      if (!_useFallback) {
        return await _storage.read(key: _keyUserSession);
      }
    } catch (_) {
      _useFallback = true;
    }
    return _memoryFallback[_keyUserSession];
  }

  Future<void> clearAll() async {
    try {
      if (!_useFallback) {
        await _storage.deleteAll();
      }
    } catch (_) {
      _useFallback = true;
    }
    _memoryFallback.clear();
  }
}
