import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagewatcher_mobile/core/network/api_error.dart';

DioException _withBody(int status, Object? body) {
  final options = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response<Object?>(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  test('reads a plain FastAPI detail string', () {
    final e = ApiException.fromDio(_withBody(400, {'detail': 'Email already registered'}));
    expect(e.statusCode, 400);
    expect(e.detail, 'Email already registered');
    expect(e.isNetworkError, isFalse);
  });

  test('reads the first pydantic validation message and strips its prefix', () {
    final e = ApiException.fromDio(
      _withBody(422, {
        'detail': [
          {'loc': ['body', 'password'], 'msg': 'Value error, Password too weak', 'type': 'value_error'},
        ],
      }),
    );
    expect(e.detail, 'Password too weak');
  });

  test('connection failures are network errors without detail', () {
    final e = ApiException.fromDio(
      DioException.connectionError(requestOptions: RequestOptions(path: '/x'), reason: 'offline'),
    );
    expect(e.isNetworkError, isTrue);
    expect(e.detail, isNull);
  });

  test('guardApi converts DioException', () async {
    await expectLater(
      guardApi<void>(() async => throw _withBody(429, {'detail': 'Slow down'})),
      throwsA(isA<ApiException>().having((e) => e.isRateLimited, 'isRateLimited', isTrue)),
    );
  });
}
