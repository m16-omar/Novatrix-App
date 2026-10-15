import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/learning_repository.dart';
import '../data/repositories/notifications_repository.dart';
import '../data/repositories/portal_repository.dart';
import '../data/repositories/teaching_repository.dart';
import 'network/api_client.dart';
import 'network/api_exception.dart';
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
final notificationsRepositoryProvider = Provider((ref) => NotificationsRepository(ref.watch(apiClientProvider)));

/// The signed-in person and what they can access.
class Session {
  const Session({required this.user, required this.roles, this.offline = false});

  final User user;
  final Roles roles;

  /// Restored from the copy saved on the device because the backend couldn't be reached.
  /// Checked again when the app comes back to the foreground ([SessionController.revalidate]).
  final bool offline;

  Session copyWith({User? user, Roles? roles}) =>
      Session(user: user ?? this.user, roles: roles ?? this.roles, offline: offline);

  Map<String, dynamic> toJson() => {'user': user.toJson(), 'roles': roles.toJson()};

  static Session? fromSaved(Map<String, dynamic>? saved) {
    if (saved == null || saved['user'] is! Map) return null;
    return Session(
      user: User.fromJson((saved['user'] as Map).cast<String, dynamic>()),
      roles: saved['roles'] is Map ? Roles.fromJson((saved['roles'] as Map).cast<String, dynamic>()) : Roles.none,
      offline: true,
    );
  }
}

class SessionController extends AsyncNotifier<Session?> {
  AuthRepository get _auth => ref.read(authRepositoryProvider);
  TokenStore get _store => ref.read(tokenStoreProvider);

  /// A returning user stays signed in. Their details are checked with the backend: if it
  /// rejects the session (expired, revoked, account deactivated) they're signed out; if it
  /// can't be reached, the copy saved on the device is used until it can.
  @override
  Future<Session?> build() async {
    if (!await _auth.hasSession()) return null;
    final saved = Session.fromSaved(await _store.readSaved());
    try {
      return await _confirm(saved);
    } on ApiException catch (e) {
      if (e.isUnreachable) return saved;
      await _auth.logout();
      return null;
    } catch (_) {
      // Something unexpected (not an answer from the backend): don't sign anyone out over it.
      return saved;
    }
  }

  /// Fetches the user and their areas, and saves them. Roles that can't be loaded fall back to
  /// the saved ones rather than to none, so nobody loses their areas to a hiccup.
  Future<Session> _confirm(Session? saved) async {
    final user = await _auth.me();
    Roles roles;
    try {
      roles = await _auth.roles();
    } catch (_) {
      roles = saved?.roles ?? Roles.none;
    }
    final session = Session(user: user, roles: roles);
    await _store.writeSaved(session.toJson());
    return session;
  }

  /// Checks a session restored offline with the backend again (called when the app returns to
  /// the foreground). Still unreachable: nothing changes.
  Future<void> revalidate() async {
    final current = state.value;
    if (current == null || !current.offline) return;
    try {
      state = AsyncData(await _confirm(current));
    } on ApiException catch (e) {
      if (!e.isUnreachable) await logout();
    } catch (_) {}
  }

  void _publish(Session session) {
    state = AsyncData(session);
    _store.writeSaved(session.toJson());
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
    _publish(session);
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
    _publish(Session(user: user, roles: Roles.none));
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
    try {
      _publish(current.copyWith(roles: await _auth.roles()));
    } catch (_) {
      // Keep the areas we know about rather than dropping them over a failed request.
    }
  }

  void setUser(User user) {
    final current = state.value;
    if (current != null) _publish(current.copyWith(user: user));
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

/* ---------- onboarding ---------- */

/// Whether this device has been through the welcome slides.
class OnboardingController extends AsyncNotifier<bool> {
  static const _key = 'nvx_onboarded';

  @override
  Future<bool> build() async => (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  Future<void> complete() async {
    state = const AsyncData(true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}

final onboardingProvider = AsyncNotifierProvider<OnboardingController, bool>(OnboardingController.new);
