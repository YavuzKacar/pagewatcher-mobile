import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Request option `extra` flags.
abstract final class AuthExtra {
  /// Don't attach the bearer token or attempt a refresh (login, register,
  /// refresh itself, ...). A 401 from those means bad credentials, not an
  /// expired session.
  static const skipAuth = 'skipAuth';
  static const _retried = 'authRetried';
}

/// Attaches the access token and transparently refreshes it on 401.
///
/// Port of the web client's axios interceptor (frontend/src/services/api.ts):
/// concurrent 401s share one in-flight `/auth/refresh` call, the original
/// request is retried once with the new token, and a rejected refresh clears
/// the session and fires [onSessionExpired].
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStorage storage,
    required Dio refreshClient,
    required Dio retryClient,
    required void Function() onSessionExpired,
  })  : _storage = storage,
        _refreshClient = refreshClient,
        _retryClient = retryClient,
        _onSessionExpired = onSessionExpired;

  final TokenStorage _storage;
  final Dio _refreshClient;
  final Dio _retryClient;
  final void Function() _onSessionExpired;

  Future<AuthTokens?>? _inFlightRefresh;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[AuthExtra.skipAuth] != true) {
      final tokens = await _storage.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final shouldRefresh = err.response?.statusCode == 401 &&
        options.extra[AuthExtra.skipAuth] != true &&
        options.extra[AuthExtra._retried] != true;
    if (!shouldRefresh) return handler.next(err);

    final current = await _storage.read();
    if (current == null) {
      _onSessionExpired();
      return handler.next(err);
    }

    AuthTokens? refreshed;
    final sentHeader = options.headers['Authorization'];
    if (sentHeader != 'Bearer ${current.accessToken}') {
      // Another request already refreshed while this one was in flight.
      refreshed = current;
    } else {
      try {
        refreshed = await (_inFlightRefresh ??=
            _refresh(current.refreshToken).whenComplete(() => _inFlightRefresh = null));
      } on DioException {
        // Network trouble during refresh: keep the session, surface the error.
        return handler.next(err);
      }
    }

    if (refreshed == null) {
      await _storage.clear();
      _onSessionExpired();
      return handler.next(err);
    }

    options.extra[AuthExtra._retried] = true;
    options.headers['Authorization'] = 'Bearer ${refreshed.accessToken}';
    try {
      handler.resolve(await _retryClient.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Returns the new pair, or null if the server rejected the refresh token.
  /// Rethrows transport errors so callers can tell "offline" from "revoked".
  Future<AuthTokens?> _refresh(String refreshToken) async {
    try {
      final res = await _refreshClient.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {AuthExtra.skipAuth: true}),
      );
      final data = res.data!;
      final tokens = AuthTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      await _storage.write(tokens);
      return tokens;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null && status >= 400 && status < 500) return null;
      rethrow;
    }
  }
}
