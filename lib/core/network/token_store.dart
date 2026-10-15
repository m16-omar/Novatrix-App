import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The signed-in session: a JWT access/refresh pair, kept in the iOS Keychain
/// or Android Keystore, with a saved copy of the person's details so a returning
/// user stays signed in while the backend can't be reached.
class Tokens {
  const Tokens({required this.access, required this.refresh});

  final String access;
  final String refresh;

  factory Tokens.fromJson(Map<String, dynamic> json) =>
      Tokens(access: json['access'] as String, refresh: json['refresh'] as String);
}

class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final FlutterSecureStorage _storage;
  static const _accessKey = 'nvx_access';
  static const _refreshKey = 'nvx_refresh';
  static const _sessionKey = 'nvx_session';

  Tokens? _cached;
  bool _loaded = false;

  Future<Tokens?> read() async {
    if (_loaded) return _cached;
    try {
      final access = await _storage.read(key: _accessKey);
      final refresh = await _storage.read(key: _refreshKey);
      _cached = access != null && refresh != null
          ? Tokens(access: access, refresh: refresh)
          : null;
    } catch (_) {
      // A keychain error must not trap someone in a broken session.
      _cached = null;
    }
    _loaded = true;
    return _cached;
  }

  /// The last user and roles the backend confirmed, as JSON. Null when signed out.
  Future<Map<String, dynamic>?> readSaved() async {
    try {
      final raw = await _storage.read(key: _sessionKey);
      return raw == null ? null : (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  Future<void> writeSaved(Map<String, dynamic>? session) async {
    try {
      if (session == null) {
        await _storage.delete(key: _sessionKey);
      } else {
        await _storage.write(key: _sessionKey, value: jsonEncode(session));
      }
    } catch (_) {
      // Saving is best effort: the session still works for this run of the app.
    }
  }

  /// Signing out (null) also removes the saved details.
  Future<void> write(Tokens? tokens) async {
    _cached = tokens;
    _loaded = true;
    try {
      if (tokens == null) {
        await _storage.delete(key: _accessKey);
        await _storage.delete(key: _refreshKey);
        await _storage.delete(key: _sessionKey);
      } else {
        await _storage.write(key: _accessKey, value: tokens.access);
        await _storage.write(key: _refreshKey, value: tokens.refresh);
      }
    } catch (_) {
      // The session still works for this run of the app.
    }
  }
}
