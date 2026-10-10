import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// Talks to the shared TIIPE & Novatrix backend.
///
/// Every request carries `X-Tenant: novatrix`. Signed-in requests carry the JWT; on a
/// 401 the client refreshes the pair once (concurrent requests share the refresh) and
/// retries. If the refresh fails, the session is cleared and [onSessionExpired] runs.
class ApiClient {
  ApiClient(this._tokens, {this.onSessionExpired})
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
          headers: {'Accept': 'application/json', 'X-Tenant': AppConfig.tenant},
          contentType: Headers.jsonContentType,
        ));

  final Dio _dio;
  final TokenStore _tokens;
  void Function()? onSessionExpired;
  Completer<bool>? _refreshing;

  Future<T> get<T>(String path, {bool auth = false, Map<String, dynamic>? query}) =>
      _send<T>('GET', path, auth: auth, query: query);

  Future<T> post<T>(String path, {Object? body, bool auth = false}) =>
      _send<T>('POST', path, body: body ?? const {}, auth: auth);

  Future<T> patch<T>(String path, {Object? body, bool auth = true}) =>
      _send<T>('PATCH', path, body: body, auth: auth);

  Future<T> delete<T>(String path, {bool auth = true}) =>
      _send<T>('DELETE', path, auth: auth);

  Future<T> _send<T>(
    String method,
    String path, {
    Object? body,
    bool auth = false,
    Map<String, dynamic>? query,
  }) async {
    Future<Response<dynamic>> attempt() async {
      final headers = <String, dynamic>{};
      if (auth) {
        final tokens = await _tokens.read();
        if (tokens != null) headers['Authorization'] = 'Bearer ${tokens.access}';
      }
      return _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method, headers: headers),
      );
    }

    try {
      Response<dynamic> response;
      try {
        response = await attempt();
      } on DioException catch (e) {
        final expired = e.response?.statusCode == 401 && auth && await _tokens.read() != null;
        if (!expired || !await _refresh()) rethrow;
        response = await attempt();
      }
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Exchanges the refresh token for a new pair. Concurrent callers share one request.
  Future<bool> _refresh() {
    final pending = _refreshing;
    if (pending != null) return pending.future;
    final completer = _refreshing = Completer<bool>();
    () async {
      try {
        final tokens = await _tokens.read();
        if (tokens == null) return completer.complete(false);
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/token/refresh/',
          data: {'refresh': tokens.refresh},
        );
        final data = res.data!;
        await _tokens.write(Tokens(
          access: data['access'] as String,
          refresh: (data['refresh'] as String?) ?? tokens.refresh,
        ));
        completer.complete(true);
      } catch (_) {
        await _tokens.write(null);
        onSessionExpired?.call();
        completer.complete(false);
      } finally {
        _refreshing = null;
      }
    }();
    return completer.future;
  }
}

/// Lists may come back plain or wrapped in the backend's paginated envelope.
List<Map<String, dynamic>> listOf(Object? data) {
  final raw = data is Map ? data['results'] : data;
  return (raw as List? ?? const []).cast<Map<String, dynamic>>();
}
