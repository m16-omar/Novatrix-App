import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

enum _Art { solutions, systems, skills }

class _Slide {
  const _Slide(this.title, this.body, this.art);
  final String title;
  final String body;
  final _Art art;
}

const _slides = [
  _Slide(
    'Technology that\nworks for you',
    'Practical digital solutions built around real people and real workflows.',
    _Art.solutions,
  ),
  _Slide(
    'Connect your\nsystems',
    'Implement reliable tools that help your organization work smarter.',
    _Art.systems,
  ),
  _Slide(
    "Build skills for\nwhat's next",
    'Learn practical technology skills with guided projects and expert support.',
    _Art.skills,
  ),
];

/// Welcome slides, shown once on a device before the first sign-in.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  bool get _last => _index == _slides.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish(String to) {
    context.go(to);
    ref.read(onboardingProvider.notifier).complete();
  }

  void _next() {
    if (_last) return _finish('/');
    _pages.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 8, 0),
                child: SizedBox(
                  height: 44,
                  child: AnimatedOpacity(
                    opacity: _last ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(onPressed: _last ? null : () => _finish('/'), child: const Text('Skip')),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => AnimatedBuilder(
                  animation: _pages,
                  builder: (context, _) {
                    final page = _pages.hasClients && _pages.position.haveDimensions ? _pages.page! : 0.0;
                    return _SlideView(slide: _slides[i], offset: i - page);
                  },
                ),
              ),
            ),
            _Dots(count: _slides.length, index: _index),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GradientButton(label: _last ? 'Get started' : 'Continue', onPressed: _next),
            ),
            SizedBox(
              height: 52,
              child: AnimatedOpacity(
                opacity: _last ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: _last ? () => _finish('/login') : null,
                  style: TextButton.styleFrom(foregroundColor: p.brand),
                  child: const Text('Log in'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.offset});

  final _Slide slide;

  /// How far this slide is from the centre of the screen, in pages (0 when fully shown).
  final double offset;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fade = (1 - offset.abs()).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Opacity(
                opacity: fade,
                child: Transform.translate(
                  offset: Offset(offset * -40, 0),
                  child: _Illustration(art: slide.art),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Opacity(
            opacity: fade,
            child: Transform.translate(
              offset: Offset(offset * 60, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slide.title, style: context.text.headlineMedium?.copyWith(height: 1.15)),
                  const SizedBox(height: 14),
                  Text(slide.body, style: context.text.bodyLarge?.copyWith(color: p.mutedForeground, height: 1.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

/* ---------- illustrations ---------- */

/// A small icon tile floating around the illustration.
class _Satellite {
  const _Satellite(this.at, this.icon, {this.tone = 0, this.size = 0.17});

  /// Position in the square, from (-1, -1) top-left to (1, 1) bottom-right.
  final Alignment at;
  final IconData icon;

  /// 0 brand purple, 1 brand pink, 2 warm accent, 3 white tile with a brand icon.
  final int tone;

  /// Tile size as a fraction of the illustration.
  final double size;
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.art});
  final _Art art;

  static const _warm = Color(0xFFF59E0B);

  List<_Satellite> get _satellites => switch (art) {
        _Art.solutions => const [
            _Satellite(Alignment(-0.82, -0.62), LucideIcons.layoutDashboard, tone: 3),
            _Satellite(Alignment(0.1, -0.95), LucideIcons.cloud, tone: 0, size: 0.2),
            _Satellite(Alignment(0.85, -0.5), LucideIcons.chartColumn, tone: 3),
            _Satellite(Alignment(-0.85, 0.55), LucideIcons.database, tone: 1),
            _Satellite(Alignment(0.82, 0.62), LucideIcons.code, tone: 0),
          ],
        _Art.systems => const [
            _Satellite(Alignment(0, -0.98), LucideIcons.cloud, tone: 0, size: 0.2),
            _Satellite(Alignment(-0.9, -0.42), LucideIcons.database, tone: 0),
            _Satellite(Alignment(0.9, -0.42), LucideIcons.settings, tone: 1),
            _Satellite(Alignment(-0.9, 0.7), LucideIcons.puzzle, tone: 2),
            _Satellite(Alignment(0.9, 0.7), LucideIcons.shieldCheck, tone: 3),
          ],
        _Art.skills => const [
            _Satellite(Alignment(0, -0.98), LucideIcons.graduationCap, tone: 0, size: 0.2),
            _Satellite(Alignment(-0.88, -0.5), LucideIcons.cloud, tone: 3),
            _Satellite(Alignment(0.88, -0.5), LucideIcons.code, tone: 1),
            _Satellite(Alignment(-0.88, 0.62), LucideIcons.lightbulb, tone: 2),
            _Satellite(Alignment(0.88, 0.62), LucideIcons.award, tone: 0),
          ],
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, c) {
        final s = math.min(320.0, math.min(c.maxWidth, c.maxHeight));
        final satellites = _satellites;
        return ExcludeSemantics(
          child: SizedBox.square(
            dimension: s,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft backdrop blob.
                Container(
                  width: s * 0.86,
                  height: s * 0.86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [p.brand.withValues(alpha: p.isDark ? 0.22 : 0.09), p.brand.withValues(alpha: 0)],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _Connectors(
                      [for (final sat in satellites) sat.at],
                      color: p.brand.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                _centerpiece(context, s),
                for (final sat in satellites)
                  Align(alignment: sat.at, child: _tile(context, sat, s)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tile(BuildContext context, _Satellite sat, double s) {
    final p = context.palette;
    final size = s * sat.size;
    final (Gradient? gradient, Color? fill, Color fg) = switch (sat.tone) {
      0 => (LinearGradient(colors: [p.brand, Color.lerp(p.brand, p.brand2, 0.35)!]), null, Colors.white),
      1 => (LinearGradient(colors: [Color.lerp(p.brand, p.brand2, 0.6)!, p.brand2]), null, Colors.white),
      2 => (const LinearGradient(colors: [_warm, Color(0xFFF97316)]), null, Colors.white),
      _ => (null, p.card, p.brand),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        color: fill,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: fill != null ? Border.all(color: p.border) : null,
        boxShadow: [
          BoxShadow(
            color: (fill != null ? Colors.black : p.brand).withValues(alpha: p.isDark ? 0.4 : 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(sat.icon, color: fg, size: size * 0.46),
    );
  }

  Widget _centerpiece(BuildContext context, double s) => switch (art) {
        _Art.solutions => _LayerStack(size: s * 0.44),
        _Art.systems => _Laptop(width: s * 0.56, screen: _ChartScreen()),
        _Art.skills => _Laptop(width: s * 0.56, screen: _LessonScreen()),
      };
}

/// Dashed lines from the centre out to each tile.
class _Connectors extends CustomPainter {
  _Connectors(this.points, {required this.color});
  final List<Alignment> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final center = size.center(Offset.zero);
    for (final a in points) {
      final end = a.alongSize(size);
      final length = (end - center).distance;
      final dir = (end - center) / length;
      // Start outside the centrepiece and stop short of the tile.
      for (var d = length * 0.3; d < length * 0.86; d += 9) {
        canvas.drawLine(center + dir * d, center + dir * math.min(d + 4.5, length * 0.86), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Connectors old) => old.color != color || old.points != points;
}

/// Three stacked layers, seen from above at an angle: the "solutions" centrepiece.
class _LayerStack extends StatelessWidget {
  const _LayerStack({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget layer(double dy, List<Color> colors, {Widget? child}) => Transform.translate(
          offset: Offset(0, dy),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(0.95)
              ..rotateZ(math.pi / 4),
            child: Container(
              width: size * 0.78,
              height: size * 0.78,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(size * 0.1),
                boxShadow: [BoxShadow(color: p.brand.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: child,
            ),
          ),
        );
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          layer(size * 0.26, [p.brand2.withValues(alpha: 0.75), p.brand2]),
          layer(size * 0.06, [Color.lerp(p.brand, p.brand2, 0.4)!, Color.lerp(p.brand, p.brand2, 0.6)!]),
          layer(
            -size * 0.14,
            [p.brand, Color.lerp(p.brand, const Color(0xFF4C1296), 0.4)!],
            child: Center(
              child: Transform.rotate(
                angle: -math.pi / 4,
                child: Icon(LucideIcons.layers, color: Colors.white, size: size * 0.24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A laptop with something on its screen.
class _Laptop extends StatelessWidget {
  const _Laptop({required this.width, required this.screen});
  final double width;
  final Widget screen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bezel = p.isDark ? const Color(0xFF2A2F45) : const Color(0xFF1E1B3A);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width,
          height: width * 0.64,
          padding: EdgeInsets.all(width * 0.035),
          decoration: BoxDecoration(
            color: bezel,
            borderRadius: BorderRadius.vertical(top: Radius.circular(width * 0.06)),
            boxShadow: [BoxShadow(color: p.brand.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 12))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(width * 0.025),
            child: ColoredBox(color: p.isDark ? p.card : Colors.white, child: screen),
          ),
        ),
        Container(
          width: width * 1.16,
          height: width * 0.05,
          decoration: BoxDecoration(
            color: Color.lerp(bezel, Colors.white, 0.25),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(width * 0.04)),
          ),
        ),
      ],
    );
  }
}

/// A mini dashboard: a header bar, a line of stats, and a bar chart.
class _ChartScreen extends StatelessWidget {
  const _ChartScreen();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        const bars = [0.35, 0.55, 0.42, 0.7, 0.6, 0.88];
        return Padding(
          padding: EdgeInsets.all(w * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (final color in [p.brand, p.brand2, p.muted])
                    Container(
                      width: w * 0.05,
                      height: w * 0.05,
                      margin: EdgeInsets.only(right: w * 0.02),
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  const Spacer(),
                  Container(width: w * 0.3, height: w * 0.04, decoration: _pill(p.muted)),
                ],
              ),
              SizedBox(height: w * 0.06),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < bars.length; i++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: w * 0.015),
                          child: FractionallySizedBox(
                            heightFactor: bars[i],
                            alignment: Alignment.bottomCenter,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: i.isEven ? [p.brand, p.brand.withValues(alpha: 0.6)] : [p.brand2, p.brand2.withValues(alpha: 0.6)],
                                ),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.02)),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A mini lesson: a video with a play button and a progress bar.
class _LessonScreen extends StatelessWidget {
  const _LessonScreen();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return Padding(
          padding: EdgeInsets.all(w * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: p.gradient,
                    borderRadius: BorderRadius.circular(w * 0.04),
                  ),
                  child: Center(
                    child: Container(
                      width: w * 0.18,
                      height: w * 0.18,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(LucideIcons.play, color: p.brand, size: w * 0.09),
                    ),
                  ),
                ),
              ),
              SizedBox(height: w * 0.05),
              Container(width: w * 0.6, height: w * 0.04, decoration: _pill(p.muted)),
              SizedBox(height: w * 0.04),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: SizedBox(
                  height: w * 0.035,
                  child: Row(
                    children: [
                      Expanded(flex: 6, child: DecoratedBox(decoration: BoxDecoration(gradient: p.gradient))),
                      Expanded(flex: 4, child: ColoredBox(color: p.muted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

BoxDecoration _pill(Color color) => BoxDecoration(color: color, borderRadius: BorderRadius.circular(99));

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Step ${index + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == index ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: i == index ? p.gradient : null,
                color: i == index ? null : p.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
        ],
      ),
    );
  }
}
