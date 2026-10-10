import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Where the app talks to. Shared with the website: the same TIIPE & Novatrix
/// backend, routed to the Novatrix schema by the `X-Tenant` header.
///
/// Override at build time:
///   flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
class AppConfig {
  AppConfig._();

  static const tenant = 'novatrix';

  /// The public website, for checkout, legal pages, and certificate links.
  static const siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: 'https://thenovatrix.com',
  );

  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv.replaceAll(RegExp(r'/+$'), '');
    // Local development: the Android emulator reaches the host machine on 10.0.2.2.
    final host = !kIsWeb && Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:8000/api/v1';
  }

  static const connectTimeout = Duration(seconds: 20);
  static const receiveTimeout = Duration(seconds: 30);

  static const supportEmail = 'hello@thenovatrix.com';
}
