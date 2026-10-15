import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/config/app_config.dart';
import 'core/data_providers.dart';
import 'core/providers.dart';
import 'core/push.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The fonts ship with the app (assets/google_fonts/): never download them, so text looks the
  // same offline and on a slow connection.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final family in ['Inter', 'SpaceGrotesk']) {
      final license = await rootBundle.loadString('assets/google_fonts/$family-OFL.txt');
      yield LicenseEntryWithLineBreaks([family == 'SpaceGrotesk' ? 'Space Grotesk' : family], license);
    }
  });
  final configurationError = AppConfig.configurationError;
  if (configurationError != null) {
    // A misbuilt release: say so plainly rather than failing on every request.
    runApp(MaterialApp(home: Scaffold(body: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(configurationError, textAlign: TextAlign.center),
    )))));
    return;
  }
  // API errors (a 403, a validation error) won't fix themselves: retry only when asked.
  runApp(ProviderScope(retry: (_, _) => null, child: const NovatrixApp()));
}

class NovatrixApp extends ConsumerStatefulWidget {
  const NovatrixApp({super.key});

  @override
  ConsumerState<NovatrixApp> createState() => _NovatrixAppState();
}

class _NovatrixAppState extends ConsumerState<NovatrixApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // A returning user restored offline is checked with the backend again whenever the app
    // comes back to the foreground.
    _lifecycle = AppLifecycleListener(onResume: () {
      ref.read(sessionProvider.notifier).revalidate();
      // Notifications may have arrived while the app was in the background.
      ref.invalidate(unreadNotificationsProvider);
    });
    // Push notifications, when this build has Firebase settings (see README).
    ref.read(pushServiceProvider).start();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'The Novatrix',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
