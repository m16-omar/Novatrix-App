import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/json.dart';
import 'data_providers.dart';
import 'providers.dart';
import 'router.dart';

/// Shows the in-app banner when a notification arrives while the app is open.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// The Firebase project the app uses for push (tiipe-17751), from its GoogleService-Info.plist and
/// google-services.json. These identify the app to Firebase; they aren't secrets (Firebase's own
/// setup tools put them in the app's code). Each can be overridden at build time with
/// --dart-define (see README, Push notifications). A platform without an app ID has push off.
class PushConfig {
  const PushConfig._();

  // Firebase gives each platform its own API key.
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'AIzaSyD5lQjw82v9kTkhxAmmEyX_gpbXyIp1cAE');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'tiipe-17751');
  static const _senderId = String.fromEnvironment('FIREBASE_SENDER_ID', defaultValue: '415922599466');
  static const _iosAppId =
      String.fromEnvironment('FIREBASE_IOS_APP_ID', defaultValue: '1:415922599466:ios:e2ed6eebb3b151ce5f7553');
  static const _androidApiKey =
      String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: 'AIzaSyCASj7_kM17smaRJ7uzEqXMmfDOS5oixsU');
  static const _androidAppId =
      String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: '1:415922599466:android:6ea0664f76b9cb835f7553');

  static FirebaseOptions? get options {
    if (kIsWeb) return null;
    final (appId, apiKey) = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => (_iosAppId, _apiKey),
      TargetPlatform.android => (_androidAppId, _androidApiKey),
      _ => ('', ''),
    };
    if ([apiKey, _projectId, _senderId, appId].any((v) => v.isEmpty)) return null;
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: _senderId,
      projectId: _projectId,
      iosBundleId: 'com.thenovatrix.app',
      storageBucket: '$_projectId.firebasestorage.app',
    );
  }
}

/// Screens a notification may open: the learner and client areas the backend links to.
const _openableRoutes = ['/learn', '/client', '/teach'];

/// The screen a notification's data asks to open, if it's one a notification may open.
String? notificationRoute(Map<String, dynamic> data) {
  final route = data['route'];
  if (route is! String || !route.startsWith('/') || route.startsWith('//')) return null;
  return _openableRoutes.any((p) => route == p || route.startsWith('$p/')) ? route : null;
}

String? _routeOf(RemoteMessage message) => notificationRoute(message.data);

/// Push notifications for assignment feedback, course announcements, and support ticket updates.
///
/// After someone signs in, the app asks permission and registers the phone with the backend;
/// signing out removes the phone's token so pushes stop reaching it. Tapping a notification opens
/// the screen it's about.
class PushService {
  PushService(this._ref);

  final Ref _ref;
  bool _ready = false;
  int? _registeredFor;
  final _subscriptions = <StreamSubscription<Object?>>[];

  bool get enabled => _ready;

  /// Called once at launch. Safe without Firebase settings: push simply stays off.
  Future<void> start() async {
    final options = PushConfig.options;
    if (options == null || _ready) return;
    try {
      await Firebase.initializeApp(options: options);
    } catch (e) {
      debugPrint('Push is off: Firebase could not start ($e).');
      return;
    }
    _ready = true;
    final messaging = FirebaseMessaging.instance;
    // On iOS, show notifications that arrive while the app is open, like the system would.
    await messaging.setForegroundNotificationPresentationOptions(alert: false, badge: true, sound: true);
    _subscriptions
      ..add(FirebaseMessaging.onMessage.listen(_showInApp))
      ..add(FirebaseMessaging.onMessageOpenedApp.listen(_open))
      ..add(messaging.onTokenRefresh.listen((token) => _register(token)));
    final launchedFrom = await messaging.getInitialMessage();
    if (launchedFrom != null) {
      // Wait for the session check and first route before navigating.
      Future<void>.delayed(const Duration(milliseconds: 800), () => _open(launchedFrom));
    }
    final session = _ref.read(sessionProvider).value;
    if (session != null) await signedIn(session.user.id);
  }

  /// Asks permission (once; the system remembers the answer) and registers this phone.
  Future<void> signedIn(int userId) async {
    if (!_ready || _registeredFor == userId) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // The FCM token needs the APNs token, which can take a moment after permission.
        for (var i = 0; i < 10 && await FirebaseMessaging.instance.getAPNSToken() == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && await _register(token)) _registeredFor = userId;
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  /// Stops pushes to this phone: the token is deleted, so the backend can't reach it any more
  /// (it switches the old token off on its next send).
  Future<void> signedOut() async {
    _registeredFor = null;
    if (!_ready) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('Push sign-out failed: $e');
    }
  }

  Future<bool> _register(String token) async {
    if (_ref.read(sessionProvider).value == null) return false;
    try {
      await _ref.read(apiClientProvider).post<Json>(
        '/notifications/push-tokens/',
        body: {
          'device_token': token,
          'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        },
        auth: true,
      );
      return true;
    } catch (e) {
      debugPrint('Could not register this phone for push: $e');
      return false;
    }
  }

  void _open(RemoteMessage message) {
    _ref.invalidate(unreadNotificationsProvider);
    final route = _routeOf(message);
    if (route != null && _ref.read(sessionProvider).value != null) _ref.read(routerProvider).go(route);
  }

  /// A notification while the app is open: a banner with a button to open it.
  void _showInApp(RemoteMessage message) {
    // It's also in the notification list now: update the bell.
    _ref.invalidate(unreadNotificationsProvider);
    _ref.invalidate(notificationsProvider);
    final notification = message.notification;
    if (notification == null) return;
    final route = _routeOf(message);
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(
          [notification.title, notification.body].whereType<String>().join('\n'),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        action: route == null ? null : SnackBarAction(label: 'View', onPressed: () => _open(message)),
      ),
    );
  }

  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(ref);
  ref.onDispose(service.dispose);
  // Register on sign-in, stop on sign-out.
  ref.listen(sessionProvider.select((s) => s.value?.user.id), (previous, next) {
    if (next != null) {
      service.signedIn(next);
    } else if (previous != null) {
      service.signedOut();
    }
  });
  return service;
});
