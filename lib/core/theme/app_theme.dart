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
    background: Color(0xFFFCFBFF),
    foreground: Color(0xFF120E22),
    card: Color(0xFFFFFFFF),
    muted: Color(0xFFF2F0FB),
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
    TextStyle? display(TextStyle? s, double size, {FontWeight weight = FontWeight.w700}) =>
        GoogleFonts.spaceGrotesk(textStyle: s, fontSize: size, fontWeight: weight, color: p.foreground, height: 1.15);

    final text = body.copyWith(
      displaySmall: display(body.displaySmall, 34),
      headlineMedium: display(body.headlineMedium, 28),
      headlineSmall: display(body.headlineSmall, 24),
      titleLarge: display(body.titleLarge, 20, weight: FontWeight.w600),
      titleMedium: body.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: body.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      bodySmall: body.bodySmall?.copyWith(color: p.mutedForeground),
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
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: brightness == Brightness.dark ? p.muted : p.border),
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      textTheme: text,
      dividerColor: p.border,
      dividerTheme: DividerThemeData(color: p.border, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
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
        indicatorColor: p.brand.withValues(alpha: 0.18),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelSmall?.copyWith(
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? p.foreground : p.mutedForeground,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: p.border)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark ? const Color(0xFF020618) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          shape: const StadiumBorder(),
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
