import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../../core/providers.dart';
import '../../../core/storage/token_storage.dart';
import 'user.dart';

/// Wraps `/auth/*` (backend/app/api/routes/auth.py). Endpoints that take
/// credentials are sent with `skipAuth` so a 401 means "wrong password",
/// not "refresh the session".
class AuthRepository {
  AuthRepository(this._dio, this._tokens);

  final Dio _dio;
  final TokenStorage _tokens;

  static final _public = Options(extra: {AuthExtra.skipAuth: true});

  Future<bool> hasStoredSession() async => (await _tokens.read()) != null;

  /// Returns `is_new_user` from the token response.
  Future<bool> login(String email, String password) =>
      _signIn('/auth/login', {'email': email, 'password': password});

  Future<bool> loginWithGoogle(String idToken) => _signIn('/auth/google', {'credential': idToken});

  Future<bool> loginWithApple(String idToken, {String? name}) =>
      _signIn('/auth/apple', {'id_token': idToken, 'name': ?name});

  Future<User> register(String email, String password) => guardApi(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/register',
          data: {'email': email, 'password': password},
          options: _public,
        );
        return User.fromJson(res.data!);
      });

  Future<User> me() => guardApi(() async {
        final res = await _dio.get<Map<String, dynamic>>('/auth/me');
        return User.fromJson(res.data!);
      });

  Future<void> forgotPassword(String email) => guardApi(
        () => _dio.post<void>('/auth/forgot-password', data: {'email': email}, options: _public),
      );

  Future<void> resetPassword(String token, String newPassword) => guardApi(
        () => _dio.post<void>(
          '/auth/reset-password',
          data: {'token': token, 'new_password': newPassword},
          options: _public,
        ),
      );

  /// Revokes the refresh token server-side (best effort) and forgets both tokens.
  Future<void> logout() async {
    final tokens = await _tokens.read();
    await _tokens.clear();
    if (tokens == null) return;
    try {
      await _dio.post<void>(
        '/auth/logout',
        data: {'refresh_token': tokens.refreshToken},
        options: _public,
      );
    } on DioException {
      // Offline or already revoked — the local session is gone either way.
    }
  }

  Future<bool> _signIn(String path, Map<String, dynamic> body) => guardApi(() async {
        final res = await _dio.post<Map<String, dynamic>>(path, data: body, options: _public);
        final data = res.data!;
        await _tokens.write(
          AuthTokens(
            accessToken: data['access_token'] as String,
            refreshToken: data['refresh_token'] as String,
          ),
        );
        return data['is_new_user'] as bool? ?? false;
      });
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider)),
);
