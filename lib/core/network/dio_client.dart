import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// [adapter] replaces the HTTP transport (tests).
Dio createApiClient({
  required TokenStorage tokenStorage,
  required void Function() onSessionExpired,
  String baseUrl = Env.apiBaseUrl,
  HttpClientAdapter? adapter,
}) {
  final options = BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    contentType: Headers.jsonContentType,
    headers: {'Accept': 'application/json'},
  );

  final dio = Dio(options);
  // A bare client so the refresh call never re-enters the interceptor.
  final refreshClient = Dio(options);
  if (adapter != null) {
    dio.httpClientAdapter = adapter;
    refreshClient.httpClientAdapter = adapter;
  }

  dio.interceptors.add(
    AuthInterceptor(
      storage: tokenStorage,
      refreshClient: refreshClient,
      retryClient: dio,
      onSessionExpired: onSessionExpired,
    ),
  );
  return dio;
}
