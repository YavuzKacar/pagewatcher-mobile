import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagewatcher_mobile/core/network/auth_interceptor.dart';
import 'package:pagewatcher_mobile/core/network/dio_client.dart';
import 'package:pagewatcher_mobile/core/storage/token_storage.dart';

typedef _Handler = Future<(int, Object?)> Function(RequestOptions options);

/// Routes every request through [handler] instead of the network.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final _Handler handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? _, Future<void>? _) async {
    requests.add(options);
    final (status, body) = await handler(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late InMemoryTokenStorage storage;
  late int sessionExpiredCount;

  setUp(() {
    storage = InMemoryTokenStorage(const AuthTokens(accessToken: 'old-access', refreshToken: 'refresh-1'));
    sessionExpiredCount = 0;
  });

  /// Builds a client whose main and refresh requests share one fake adapter.
  (Dio, _FakeAdapter) build(_Handler handler) {
    final adapter = _FakeAdapter(handler);
    final dio = createApiClient(
      tokenStorage: storage,
      onSessionExpired: () => sessionExpiredCount++,
      baseUrl: 'https://api.test/api/v1',
      adapter: adapter,
    );
    return (dio, adapter);
  }

  Future<(int, Object?)> refreshOk(RequestOptions _) async =>
      (200, {'access_token': 'new-access', 'refresh_token': 'refresh-2', 'token_type': 'bearer'});

  test('attaches the bearer token', () async {
    final (dio, adapter) = build((o) async => (200, {'ok': true}));
    await dio.get<dynamic>('/monitors/');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer old-access');
  });

  test('401 → refreshes once, stores the new pair and retries', () async {
    final (dio, adapter) = build((o) async {
      if (o.path == '/auth/refresh') return refreshOk(o);
      final auth = o.headers['Authorization'];
      return auth == 'Bearer new-access' ? (200, {'ok': true}) : (401, {'detail': 'expired'});
    });

    final res = await dio.get<Map<String, dynamic>>('/monitors/');

    expect(res.data, {'ok': true});
    expect(adapter.requests.map((r) => r.path), ['/monitors/', '/auth/refresh', '/monitors/']);
    final tokens = await storage.read();
    expect(tokens?.accessToken, 'new-access');
    expect(tokens?.refreshToken, 'refresh-2');
    expect(sessionExpiredCount, 0);
  });

  test('concurrent 401s share a single refresh call', () async {
    final (dio, adapter) = build((o) async {
      if (o.path == '/auth/refresh') {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return refreshOk(o);
      }
      return o.headers['Authorization'] == 'Bearer new-access' ? (200, {'ok': true}) : (401, null);
    });

    await Future.wait([dio.get<dynamic>('/a'), dio.get<dynamic>('/b'), dio.get<dynamic>('/c')]);

    expect(adapter.requests.where((r) => r.path == '/auth/refresh'), hasLength(1));
  });

  test('rejected refresh clears the session and notifies', () async {
    final (dio, _) = build((o) async => o.path == '/auth/refresh' ? (401, {'detail': 'revoked'}) : (401, null));

    await expectLater(dio.get<dynamic>('/monitors/'), throwsA(isA<DioException>()));
    expect(await storage.read(), isNull);
    expect(sessionExpiredCount, 1);
  });

  test('skipAuth requests (e.g. wrong password) never trigger a refresh', () async {
    final (dio, adapter) = build((o) async => (401, {'detail': 'Incorrect email or password'}));

    await expectLater(
      dio.post<dynamic>('/auth/login', options: Options(extra: {AuthExtra.skipAuth: true})),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
    expect(adapter.requests, hasLength(1));
    expect(await storage.read(), isNotNull);
  });

  test('network failure during refresh keeps the session', () async {
    final (dio, _) = build((o) async {
      if (o.path == '/auth/refresh') {
        throw DioException.connectionError(requestOptions: o, reason: 'offline');
      }
      return (401, null);
    });

    await expectLater(dio.get<dynamic>('/monitors/'), throwsA(isA<DioException>()));
    expect(await storage.read(), isNotNull);
    expect(sessionExpiredCount, 0);
  });
}
