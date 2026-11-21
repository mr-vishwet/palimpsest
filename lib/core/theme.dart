import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The V7 colours as direct `static const` values.
///
/// Field access on the const [Palette.v7] object (`Palette.v7.gold`)
/// is not accepted as a constant expression in `const` constructor
/// calls, so every `const` context uses these instead (e.g.
/// `V7Colors.gold`). [Palette.v7] is built from the same values, so
/// the two spellings are identical at runtime; non-`const` code
/// keeps using `Palette.v7.*` / `palette.*`.
class V7Colors {
  V7Colors._();

  static const Color bg0 = Color(0xFF111110);
  static const Color bg1 = Color(0xFF161513);
  static const Color bg2 = Color(0xFF1C1917);
  static const Color ink = Color(0xFFFFFFFF);
  static const Color parchment = Color(0xFFE7DDC8);
  static const Color muted = Color(0xFFA8A29E);
  static const Color glass = Color(0x14FFFFFF);
  static const Color glassStrong = Color(0x21FFFFFF);
  static const Color hairline = Color(0x26FFFFFF);
  static const Color gold = Color(0xFFD4A853);
  static const Color amber = Color(0xFFF59E0B);
  static const Color dawn = Color(0xFFFDE68A);
  static const Color green = Color(0xFF34D399);
  static const Color pink = Color(0xFFF472B6);
  static const Color cyan = Color(0xFF67E8F9);
  static const Color blue = Color(0xFF60A5FA);
  static const Color danger = Color(0xFFF87171);
  static const Color onGold = Color(0xFF221C15);
}

/// The V7 animated-essence palette: warm charcoal space, parchment
/// secondary text, gold → amber gradient CTAs, film-night cyan accents.
///
/// The palette is isolated in [Palette] so phase 2 can add a light
/// palette and a ThemeMode switch without touching any screen. Phase 1
/// ships the single V7 theme as [AppTheme.current].
class Palette {
  const Palette({
    required this.bg0,
    required this.bg1,
    required this.bg2,
    required this.ink,
    required this.parchment,
    required this.muted,
    required this.glass,
    required this.glassStrong,
    required this.hairline,
    required this.gold,
    required this.amber,
    required this.dawn,
    required this.green,
    required this.pink,
    required this.cyan,
    required this.blue,
    required this.danger,
    required this.onGold,
  });

  /// The V7 palette — near-black #111110 → warm charcoal #1C1917.
  /// Built from [V7Colors] so the two spellings stay identical.
  static const Palette v7 = Palette(
    bg0: V7Colors.bg0,
    bg1: V7Colors.bg1,
    bg2: V7Colors.bg2,
    ink: V7Colors.ink,
    parchment: V7Colors.parchment,
    muted: V7Colors.muted,
    glass: V7Colors.glass,
    glassStrong: V7Colors.glassStrong,
    hairline: V7Colors.hairline,
    gold: V7Colors.gold,
    amber: V7Colors.amber,
    dawn: V7Colors.dawn,
    green: V7Colors.green,
    pink: V7Colors.pink,
    cyan: V7Colors.cyan,
    blue: V7Colors.blue,
    danger: V7Colors.danger,
    onGold: V7Colors.onGold,
  );

  final Color bg0;
  final Color bg1;
  final Color bg2;
  final Color ink;
  final Color parchment;
  final Color muted;
  final Color glass;
  final Color glassStrong;
  final Color hairline;
  final Color gold;
  final Color amber;
  final Color dawn;
  final Color green;
  final Color pink;
  final Color cyan;
  final Color blue;
  final Color danger;
  final Color onGold;

  /// The gold → amber gradient used for primary CTAs and the memory orb.
  LinearGradient get ctaGradient => LinearGradient(
        colors: <Color>[gold, amber],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// The warm charcoal space gradient behind every screen.
  LinearGradient get spaceGradient => LinearGradient(
        colors: <Color>[bg0, bg1, bg2],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}

/// App theme built from [Palette.v7].
///
/// Phase 2: add `Palette.light` and a `ThemeMode` toggle here; screens
/// read colours from `AppTheme.palette` and `Theme.of(context)`, never
/// from hardcoded values.
class AppTheme {
  AppTheme._();

  /// The active palette. Single theme in phase 1.
  static const Palette palette = Palette.v7;

  /// The phase-1 theme data.
  static ThemeData get current {
    const p = Palette.v7;
    final baseText = GoogleFonts.spaceGroteskTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: V7Colors.gold,
        onPrimary: V7Colors.onGold,
        secondary: V7Colors.amber,
        surface: V7Colors.bg1,
        onSurface: V7Colors.ink,
        error: V7Colors.danger,
      ),
      scaffoldBackgroundColor: p.bg0,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: V7Colors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: p.glass,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: V7Colors.hairline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.gold,
          foregroundColor: p.onGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.parchment,
          side: const BorderSide(color: V7Colors.hairline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.onGold
              : p.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.gold
              : p.muted.withValues(alpha: 0.4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.glass,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: V7Colors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: V7Colors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: V7Colors.gold, width: 1.5),
        ),
        hintStyle: TextStyle(color: p.muted),
      ),
      textTheme: baseText.copyWith(
        displaySmall: baseText.displaySmall!.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: p.ink,
          height: 1.1,
        ),
        headlineSmall: baseText.headlineSmall!.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: p.ink,
          height: 1.15,
        ),
        titleLarge: baseText.titleLarge!.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: p.ink,
        ),
        titleMedium: baseText.titleMedium!.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: p.ink,
        ),
        titleSmall: baseText.titleSmall!.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: p.parchment,
        ),
        bodyLarge: baseText.bodyLarge!.copyWith(fontSize: 16, color: p.ink),
        bodyMedium: baseText.bodyMedium!.copyWith(fontSize: 14, color: p.ink),
        bodySmall: baseText.bodySmall!.copyWith(fontSize: 12, color: p.muted),
        labelLarge: baseText.labelLarge!.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: p.onGold,
        ),
      ),
    );
  }

  /// JetBrains Mono for counts, timestamps and provenance metadata.
  static TextStyle mono({
    double size = 12,
    Color? color,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        color: color ?? Palette.v7.muted,
        fontWeight: weight,
      );

  /// Kicker style: small caps-ish parchment label above headings.
  static TextStyle kicker({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        color: (color ?? Palette.v7.parchment).withValues(alpha: 0.85),
      );
}
