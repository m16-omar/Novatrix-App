import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette, converted from the website's OKLCH tokens (src/styles.css).
class Palette {
  const Palette({
    required this.background,
    required this.foreground,
    required this.card,
    required this.muted,
    required this.mutedForeground,
    required this.border,
    required this.brand,
    required this.brand2,
    required this.destructive,
    required this.success,
    required this.warning,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color muted;
  final Color mutedForeground;
  final Color border;
  final Color brand;
  final Color brand2;
  final Color destructive;
  final Color success;
  final Color warning;

  static const light = Palette(
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF120E22),
    card: Color(0xFFFFFFFF),
    muted: Color(0xFFF5F3FC),
    mutedForeground: Color(0xFF626079),
    border: Color(0xFFE6E2F0),
    brand: Color(0xFF981DEB),
    brand2: Color(0xFFE934BE),
    destructive: Color(0xFFDC2626),
    success: Color(0xFF047857),
    warning: Color(0xFFB45309),
  );

  static const dark = Palette(
    background: Color(0xFF020618),
    foreground: Color(0xFFF8FAFC),
    card: Color(0xFF0F172B),
    muted: Color(0xFF1D293D),
    mutedForeground: Color(0xFF90A1B9),
    border: Color(0x1AFFFFFF),
    brand: Color(0xFFB74BFF),
    brand2: Color(0xFFFB48CE),
    destructive: Color(0xFFFF6467),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
  );

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [brand, brand2],
      );

  bool get isDark => background.computeLuminance() < 0.5;

  /// The website's `gradient-brand` in its light theme, whatever the app's theme: the splash uses it
  /// so it matches the native launch screen (design/splash/splash-background.png).
  static const splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF981DEB), Color(0xFFE934BE)],
  );

  List<BoxShadow> get cardShadow => isDark
      ? const []
      : [BoxShadow(color: const Color(0xFF2A0A52).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))];
}

/// The page background: the base colour with soft purple and pink glows at the top, like the website's hero.
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Light mode stays clean and white; the glow is for dark mode.
    if (!p.isDark) return ColoredBox(color: p.background, child: child);
    const strength = 1.0;
    Widget glow(Alignment center, double radius, Color color, double alpha) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: center,
              radius: radius,
              colors: [color.withValues(alpha: alpha * strength), color.withValues(alpha: 0)],
            ),
          ),
        );
    return ColoredBox(
      color: p.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          glow(const Alignment(1.2, -1.1), 1.3, p.brand, 0.30),
          glow(const Alignment(-1.3, -0.55), 0.9, p.brand2, 0.16),
          glow(const Alignment(0.4, 1.4), 1.0, p.brand, 0.08),
          child,
        ],
      ),
    );
  }
}

/// Paints [BrandBackdrop] under each page so it moves with the page during transitions.
class _BackdropTransitions extends PageTransitionsBuilder {
  const _BackdropTransitions(this.inner);
  final PageTransitionsBuilder inner;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => inner.delegatedTransition;

  @override
  Duration get transitionDuration => inner.transitionDuration;

  @override
  Duration get reverseTransitionDuration => inner.reverseTransitionDuration;

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      inner.buildTransitions(route, context, animation, secondaryAnimation, BrandBackdrop(child: child));
}

extension PaletteContext on BuildContext {
  Palette get palette => Theme.of(this).brightness == Brightness.dark ? Palette.dark : Palette.light;
  TextTheme get text => Theme.of(this).textTheme;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Palette.light, Brightness.light);
  static ThemeData dark() => _build(Palette.dark, Brightness.dark);

  static ThemeData _build(Palette p, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final body = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: p.foreground,
      displayColor: p.foreground,
    );
    TextStyle? display(TextStyle? s, double size, {FontWeight weight = FontWeight.w700}) => GoogleFonts.spaceGrotesk(
          textStyle: s,
          fontSize: size,
          fontWeight: weight,
          color: p.foreground,
          height: 1.12,
          letterSpacing: size >= 24 ? -0.8 : -0.3,
        );

    final text = body.copyWith(
      displaySmall: display(body.displaySmall, 34),
      headlineMedium: display(body.headlineMedium, 28),
      headlineSmall: display(body.headlineSmall, 24),
      titleLarge: display(body.titleLarge, 20, weight: FontWeight.w600),
      titleMedium: body.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: body.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      // Material's default letter spacing (0.25–0.5) spreads Inter out too much for reading.
      bodyLarge: body.bodyLarge?.copyWith(letterSpacing: 0.1),
      bodyMedium: body.bodyMedium?.copyWith(letterSpacing: 0.1),
      bodySmall: body.bodySmall?.copyWith(color: p.mutedForeground, letterSpacing: 0.15),
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: p.brand,
      brightness: brightness,
      primary: p.brand,
      onPrimary: Colors.white,
      secondary: p.brand2,
      surface: p.background,
      onSurface: p.foreground,
      error: p.destructive,
    ).copyWith(surfaceContainerLowest: p.card, outline: p.border, outlineVariant: p.border);

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: brightness == Brightness.dark ? p.muted : p.border),
    );

    return base.copyWith(
      colorScheme: scheme,
      // Pages are transparent: BrandBackdrop is painted under each one by the page transitions.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: p.background,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _BackdropTransitions(PredictiveBackPageTransitionsBuilder()),
          TargetPlatform.iOS: _BackdropTransitions(CupertinoPageTransitionsBuilder()),
          TargetPlatform.macOS: _BackdropTransitions(CupertinoPageTransitionsBuilder()),
          TargetPlatform.windows: _BackdropTransitions(ZoomPageTransitionsBuilder()),
          TargetPlatform.linux: _BackdropTransitions(ZoomPageTransitionsBuilder()),
        },
      ),
      textTheme: text,
      dividerColor: p.border,
      dividerTheme: DividerThemeData(color: p.border, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        height: 62,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelSmall?.copyWith(
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? p.brand : p.mutedForeground,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? p.brand : p.mutedForeground, size: 22),
        ),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.border)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark ? p.card.withValues(alpha: 0.7) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        prefixIconColor: p.mutedForeground,
        suffixIconColor: p.mutedForeground,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: p.brand, width: 2)),
        errorBorder: inputBorder.copyWith(borderSide: BorderSide(color: p.destructive)),
        focusedErrorBorder: inputBorder.copyWith(borderSide: BorderSide(color: p.destructive, width: 2)),
        labelStyle: TextStyle(color: p.mutedForeground),
        hintStyle: TextStyle(color: p.mutedForeground),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.foreground,
          side: BorderSide(color: brightness == Brightness.dark ? p.muted : p.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.brand, textStyle: text.labelLarge),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.card,
        selectedColor: p.brand,
        side: BorderSide(color: brightness == Brightness.dark ? p.muted : p.border),
        shape: const StadiumBorder(),
        labelStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        secondaryLabelStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
        checkmarkColor: Colors.white,
        showCheckmark: false,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.foreground,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.background),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.brand),
      listTileTheme: ListTileThemeData(iconColor: p.brand, textColor: p.foreground),
    );
  }
}
