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

  static const _apiFromEnv = String.fromEnvironment('API_BASE_URL');

  /// Why this build can't talk to the backend, or null when it can. Release builds must be given an
  /// https API_BASE_URL (see tool/build_release.sh); the local default only works in debug.
  static String? get configurationError {
    if (!kReleaseMode) return null;
    if (_apiFromEnv.isEmpty) return 'This build has no API address. Build it with --dart-define=API_BASE_URL=https://…';
    if (!_apiFromEnv.startsWith('https://')) return 'The API address must use https in a release build.';
    return null;
  }

  static String get apiBaseUrl {
    if (_apiFromEnv.isNotEmpty) return _apiFromEnv.replaceAll(RegExp(r'/+$'), '');
    // Local development: the Android emulator reaches the host machine on 10.0.2.2.
    final host = !kIsWeb && Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:8000/api/v1';
  }

  /// Whether the cart takes people to the payment page. On by choice on every platform, including iOS.
  ///
  /// App Store risk: Apple may reject iOS apps that send people to pay outside the App Store for
  /// digital services used in the app (guideline 3.1.1). If a review requires it, return
  /// `defaultTargetPlatform != TargetPlatform.iOS` here: the iOS cart then sends an enrollment
  /// enquiry instead, and free courses still enroll directly.
  static bool get allowsWebCheckout => true;

  static const connectTimeout = Duration(seconds: 20);
  static const receiveTimeout = Duration(seconds: 30);

  static const supportEmail = 'hello@thenovatrix.com';
}
