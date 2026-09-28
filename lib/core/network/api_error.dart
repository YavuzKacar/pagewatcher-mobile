import 'package:dio/dio.dart';

/// A request failure with the backend's user-facing `detail` message, when it
/// sent one. FastAPI returns `{detail: string}` for HTTPExceptions and
/// `{detail: [{msg, loc, ...}]}` for validation (422) errors.
class ApiException implements Exception {
  const ApiException({this.statusCode, this.detail, this.isNetworkError = false});

  factory ApiException.fromDio(DioException e) {
    final isNetwork = switch (e.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        true,
      _ => false,
    };
    return ApiException(
      statusCode: e.response?.statusCode,
      detail: _extractDetail(e.response?.data),
      isNetworkError: isNetwork,
    );
  }

  final int? statusCode;
  final String? detail;
  final bool isNetworkError;

  bool get isUnauthorized => statusCode == 401;
  bool get isRateLimited => statusCode == 429;

  static String? _extractDetail(Object? data) {
    if (data is! Map) return null;
    final detail = data['detail'];
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] is String) {
        // pydantic prefixes messages like "Value error, ..." — strip it.
        return (first['msg'] as String).replaceFirst(RegExp(r'^Value error,\s*'), '');
      }
    }
    return null;
  }

  @override
  String toString() => 'ApiException($statusCode, $detail)';
}

/// Runs [request], converting any [DioException] into an [ApiException].
Future<T> guardApi<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (e) {
    if (e.error is ApiException) throw e.error! as ApiException;
    throw ApiException.fromDio(e);
  }
}
