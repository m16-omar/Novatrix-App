import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

/// Shown briefly while the stored session is checked.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NovatrixLogo(height: 72),
              SizedBox(height: 32),
              SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
            ],
          ),
        ),
      );
}
