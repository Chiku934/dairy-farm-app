import 'package:dio/dio.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/user_session.dart';

class AuthRepository {
  final Dio _dio;
  final SecureStorageService _storage;

  AuthRepository({
    required Dio dio,
    required SecureStorageService storage,
  })  : _dio = dio,
        _storage = storage;

  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final envelope = response.data as Map<String, dynamic>;
      final data = (envelope['data'] ?? envelope) as Map<String, dynamic>;

      final session = UserSession.fromJson(data);

      await _storage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      await _storage.saveUserSession(session.serialize());

      return session;
    } on DioException catch (e) {
      final errorMsg = _extractErrorMessage(e);
      throw Exception(errorMsg);
    }
  }

  Future<UserSession?> restoreSession() async {
    final raw = await _storage.getUserSession();
    if (raw == null || raw.isEmpty) return null;
    return UserSession.deserialize(raw);
  }

  Future<UserSession> refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final envelope = response.data as Map<String, dynamic>;
      final data = (envelope['data'] ?? envelope) as Map<String, dynamic>;

      final session = UserSession.fromJson(data);

      await _storage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      await _storage.saveUserSession(session.serialize());

      return session;
    } on DioException catch (e) {
      await _storage.clearAll();
      final errorMsg = _extractErrorMessage(e);
      throw Exception(errorMsg);
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      await _dio.post(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } catch (_) {
      // Local logout proceeds even if network fails
    } finally {
      await _storage.clearAll();
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          if (data['message'] is List) {
            return (data['message'] as List).join(', ');
          }
          return data['message'].toString();
        }
        if (data['error'] != null) {
          return data['error'].toString();
        }
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your network connectivity.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Unable to reach the server. Verify your internet or server connection.';
    }
    return e.message ?? 'An unexpected authentication error occurred.';
  }
}
