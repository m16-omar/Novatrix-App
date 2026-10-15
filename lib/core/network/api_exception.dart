import 'package:dio/dio.dart';

/// A failed API call, with a message fit to show people and any per-field errors.
///
/// The backend wraps errors as `{ success: false, status_code, error_type, detail }`,
/// where `detail` is DRF's usual payload: `{ field: ["msg"] }` for validation, or a
/// string / `{ detail: "msg" }` otherwise. Some auth views answer `{ message }` instead.
class ApiException implements Exception {
  ApiException(this.message, {this.status = 0, this.fieldErrors = const {}, this.code, this.info = const {}});

  final String message;
  final int status;
  final Map<String, List<String>> fieldErrors;

  /// The backend's machine-readable reason, when it gives one (e.g. "code_invalid").
  final String? code;

  /// Extra numbers some errors carry, such as `retry_after_seconds` or `attempts_left`.
  final Map<String, int> info;

  String? field(String name) => fieldErrors[name]?.first;

  /// The server couldn't be reached or is failing: not an answer about this request or this account.
  bool get isUnreachable => status == 0 || status >= 500;

  /// The first field error, or the general message.
  String get firstError =>
      fieldErrors.values.isNotEmpty ? fieldErrors.values.first.first : message;

  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    if (response == null) {
      return ApiException(
        "We couldn't reach our server. Check your connection and try again.",
      );
    }
    return ApiException.fromResponse(response.statusCode ?? 0, response.data);
  }

  factory ApiException.fromResponse(int status, Object? payload) {
    final fieldErrors = <String, List<String>>{};
    final info = <String, int>{};
    String? message;
    String? code;
    if (payload is Map) {
      if (payload['message'] is String) message = payload['message'] as String;
      if (payload['code'] is String) code = payload['code'] as String;
      payload.forEach((key, value) {
        if (value is int && key != 'status_code') info['$key'] = value;
      });
      final detail = payload['detail'];
      if (detail is String) {
        message = detail;
      } else if (detail is Map) {
        detail.forEach((key, value) {
          final messages = (value is List ? value : [value]).map((v) => '$v').toList();
          if (key == 'code') {
            code = messages.first;
          } else if (key == 'detail' || key == 'non_field_errors') {
            message = messages.first;
          } else {
            fieldErrors['$key'] = messages;
          }
        });
      }
    }
    message ??= switch (status) {
      400 => 'Some details need attention.',
      401 => 'Please log in to continue.',
      403 => "You don't have access to this.",
      404 => "We couldn't find that.",
      429 => 'Too many attempts. Please wait a minute and try again.',
      _ => 'Something went wrong on our side. Please try again.',
    };
    // Don't show raw server internals.
    if (status >= 500) message = 'Something went wrong on our side. Please try again.';
    return ApiException(message!, status: status, fieldErrors: fieldErrors, code: code, info: info);
  }

  @override
  String toString() => message;
}

/// A readable message for any error thrown while loading or saving.
String errorMessage(Object error) =>
    error is ApiException ? error.message : 'Something went wrong. Please try again.';
