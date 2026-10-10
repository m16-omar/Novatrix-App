import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/learning_repository.dart';
import '../data/repositories/portal_repository.dart';
import '../data/repositories/teaching_repository.dart';
import 'network/api_client.dart';
import 'network/token_store.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(ref.watch(tokenStoreProvider));
  // A refresh that fails means the session is over: sign out everywhere.
  client.onSessionExpired = () => ref.read(sessionProvider.notifier).expire();
  return client;
});

final authRepositoryProvider =
    Provider((ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStoreProvider)));
final catalogRepositoryProvider = Provider((ref) => CatalogRepository(ref.watch(apiClientProvider)));
final learningRepositoryProvider = Provider((ref) => LearningRepository(ref.watch(apiClientProvider)));
final teachingRepositoryProvider = Provider((ref) => TeachingRepository(ref.watch(apiClientProvider)));
final portalRepositoryProvider = Provider((ref) => PortalRepository(ref.watch(apiClientProvider)));

/// The signed-in person and what they can access.
class Session {
  const Session({required this.user, required this.roles});

  final User user;
  final Roles roles;

  Session copyWith({User? user, Roles? roles}) => Session(user: user ?? this.user, roles: roles ?? this.roles);
}

class SessionController extends AsyncNotifier<Session?> {
  AuthRepository get _auth => ref.read(authRepositoryProvider);

  @override
  Future<Session?> build() async {
    if (!await _auth.hasSession()) return null;
    try {
      final results = await Future.wait([_auth.me(), _roles()]);
      return Session(user: results[0] as User, roles: results[1] as Roles);
    } catch (_) {
      // Expired, revoked, or the API is unreachable: start signed out.
      await _auth.logout();
      return null;
    }
  }

  Future<Roles> _roles() async {
    try {
      return await _auth.roles();
    } catch (_) {
      return Roles.none;
    }
  }

  Future<Session> login(String email, String password) async {
    final user = await _auth.login(email, password);
    final session = Session(user: user, roles: await _roles());
    state = AsyncData(session);
    return session;
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String phone = '',
  }) async {
    final user = await _auth.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );
    state = AsyncData(Session(user: user, roles: Roles.none));
  }

  Future<void> logout() async {
    await _auth.logout();
    state = const AsyncData(null);
  }

  /// Called when the API reports the session can't be renewed.
  void expire() => state = const AsyncData(null);

  Future<void> refreshRoles() async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(roles: await _roles()));
  }

  void setUser(User user) {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(user: user));
  }
}

final sessionProvider = AsyncNotifierProvider<SessionController, Session?>(SessionController.new);

/* ---------- theme ---------- */

class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'nvx_theme';

  @override
  ThemeMode build() {
    SharedPreferences.getInstance().then((prefs) {
      final saved = prefs.getString(_key);
      final mode = ThemeMode.values.where((m) => m.name == saved).firstOrNull;
      if (mode != null && mode != state) state = mode;
    });
    return ThemeMode.system;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
