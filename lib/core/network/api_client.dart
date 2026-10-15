import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// Talks to the shared TIIPE & Novatrix backend.
///
/// Every request carries `X-Tenant: novatrix`. Signed-in requests carry the JWT; on a
/// 401 the client refreshes the pair once (concurrent requests share the refresh) and
/// retries. If the backend refuses the refresh, the session is cleared and
/// [onSessionExpired] runs. If it can't be reached, the session is kept and the request
/// fails with a connection error, so a returning user isn't signed out by an outage.
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
  Completer<_Refresh>? _refreshing;

  /// Why the last refresh got no usable answer, to report instead of the original 401.
  DioException? _refreshFailure;

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
        if (!expired) rethrow;
        switch (await _refresh()) {
          case _Refresh.renewed:
            response = await attempt();
          case _Refresh.rejected:
            rethrow;
          case _Refresh.unreachable:
            final failure = _refreshFailure;
            throw failure == null
                ? ApiException("We couldn't reach our server. Check your connection and try again.")
                : ApiException.fromDio(failure);
        }
      }
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Exchanges the refresh token for a new pair. Concurrent callers share one request.
  Future<_Refresh> _refresh() {
    final pending = _refreshing;
    if (pending != null) return pending.future;
    final completer = _refreshing = Completer<_Refresh>();
    () async {
      try {
        final tokens = await _tokens.read();
        if (tokens == null) return completer.complete(_Refresh.rejected);
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/token/refresh/',
          data: {'refresh': tokens.refresh},
        );
        final data = res.data!;
        await _tokens.write(Tokens(
          access: data['access'] as String,
          refresh: (data['refresh'] as String?) ?? tokens.refresh,
        ));
        completer.complete(_Refresh.renewed);
      } on DioException catch (e) {
        final status = e.response?.statusCode ?? 0;
        if (status == 0 || status >= 500) {
          // No answer, or the server is failing: keep the session and try again later.
          _refreshFailure = e;
          completer.complete(_Refresh.unreachable);
        } else {
          // The backend refused the refresh token (expired, revoked, or the account is inactive).
          await _tokens.write(null);
          onSessionExpired?.call();
          completer.complete(_Refresh.rejected);
        }
      } catch (_) {
        await _tokens.write(null);
        onSessionExpired?.call();
        completer.complete(_Refresh.rejected);
      } finally {
        _refreshing = null;
      }
    }();
    return completer.future;
  }
}

enum _Refresh { renewed, rejected, unreachable }

/// Lists may come back plain or wrapped in the backend's paginated envelope.
List<Map<String, dynamic>> listOf(Object? data) {
  final raw = data is Map ? data['results'] : data;
  return (raw as List? ?? const []).cast<Map<String, dynamic>>();
}
