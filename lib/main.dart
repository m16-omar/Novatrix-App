import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // API errors (a 403, a validation error) won't fix themselves: retry only when asked.
  runApp(ProviderScope(retry: (_, _) => null, child: const NovatrixApp()));
}

class NovatrixApp extends ConsumerWidget {
  const NovatrixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: 'The Novatrix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ref.watch(themeModeProvider),
        routerConfig: ref.watch(routerProvider),
      );
}
