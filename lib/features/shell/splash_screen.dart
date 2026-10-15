import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Shown briefly while the stored session is checked. It picks up from the native launch screen
/// (same gradient, same logo in the same place), so the handoff is seamless.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final _dots = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _intro.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fadeIn = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: Palette.splashGradient),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Matches the native launch image: 178pt wide, centred on the screen.
            Image.asset('assets/images/logo-white.png', width: 178, semanticLabel: 'The Novatrix'),
            Align(
              alignment: const Alignment(0, 0.24),
              child: FadeTransition(
                opacity: fadeIn,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Build. Implement. Empower.',
                      style: context.text.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                    const SizedBox(height: 40),
                    AnimatedBuilder(
                      animation: _dots,
                      builder: (_, _) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < 4; i++) _dot(i),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A dot that brightens and lifts in turn, so the row reads as a wave.
  Widget _dot(int i) {
    final phase = (_dots.value - i * 0.18) % 1.0;
    final t = math.sin(phase * math.pi).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Transform.translate(
        offset: Offset(0, -4 * t),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.4 + 0.6 * t),
          ),
        ),
      ),
    );
  }
}
