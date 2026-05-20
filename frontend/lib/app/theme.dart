import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Brand colour tokens from the Drivly design system (dark-first).
///
/// Use these directly for bespoke colours; semantic colours
/// (`colorScheme.primary`, etc.) are wired from these in [DrivlyTheme].
class BrandColors {
  BrandColors._();

  static const Color background = Color(0xFF1B1D2A);
  static const Color surface = Color(0xFF262838);
  static const Color surface2 = Color(0xFF2F3144);
  static const Color foreground = Color(0xFFF5F6FA);
  static const Color mutedFg = Color(0xFFA2A6B8);
  static const Color primary = Color(0xFFD6F25C); // Electric Lime
  static const Color primaryFg = Color(0xFF1B1D2A);
  static const Color accent = Color(0xFFE68A4D); // Warm Orange
  static const Color success = Color(0xFF7BE0A6);
  static const Color warning = Color(0xFFF0C75A);
  static const Color destructive = Color(0xFFE5604F);
  static const Color border = Color(0xFF3A3D52);
}

/// Spacing scale (dp). Matches the design-system spacing tokens.
class Spacing {
  Spacing._();
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20; // default screen padding
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
}

/// Corner radii tokens.
class Radii {
  Radii._();
  static const double sm = 8;
  static const double md = 12; // fields, buttons, default cards
  static const double card = 16;
  static const double pill = 999;
}

class DrivlyTheme {
  DrivlyTheme._();

  static const _scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: BrandColors.primary,
    onPrimary: BrandColors.primaryFg,
    secondary: BrandColors.accent,
    onSecondary: BrandColors.primaryFg,
    error: BrandColors.destructive,
    onError: Colors.white,
    surface: BrandColors.surface,
    onSurface: BrandColors.foreground,
    surfaceContainerHighest: BrandColors.surface2,
    outline: BrandColors.border,
  );

  /// The single, dark theme used across the app.
  static ThemeData get dark {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);

    return base.copyWith(
      colorScheme: _scheme,
      scaffoldBackgroundColor: BrandColors.background,
      canvasColor: BrandColors.background,
      dividerColor: BrandColors.border,
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: BrandColors.background,
        foregroundColor: BrandColors.foreground,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: BrandColors.foreground,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BrandColors.primary,
          foregroundColor: BrandColors.primaryFg,
          disabledBackgroundColor: BrandColors.primary.withValues(alpha: 0.4),
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandColors.foreground,
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: BrandColors.foreground.withValues(alpha: 0.3)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: BrandColors.primary),
      ),
      cardTheme: CardThemeData(
        color: BrandColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: const BorderSide(color: BrandColors.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BrandColors.surface,
        selectedColor: BrandColors.primary,
        side: const BorderSide(color: BrandColors.border),
        labelStyle: const TextStyle(color: BrandColors.foreground),
        secondaryLabelStyle: const TextStyle(color: BrandColors.primaryFg),
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BrandColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: BrandColors.mutedFg),
        labelStyle: const TextStyle(color: BrandColors.mutedFg),
        prefixIconColor: BrandColors.mutedFg,
        suffixIconColor: BrandColors.mutedFg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: const BorderSide(color: BrandColors.surface2, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: const BorderSide(color: BrandColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: const BorderSide(color: BrandColors.destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: const BorderSide(color: BrandColors.destructive, width: 2),
        ),
        errorStyle: const TextStyle(color: BrandColors.destructive, fontSize: 12),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: BrandColors.surface,
        selectedItemColor: BrandColors.primary,
        unselectedItemColor: BrandColors.mutedFg,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: BrandColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.card)),
        ),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: BrandColors.surface),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: BrandColors.surface2,
        contentTextStyle: TextStyle(color: BrandColors.foreground),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BrandColors.primary,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base
        .apply(
          bodyColor: BrandColors.foreground,
          displayColor: BrandColors.foreground,
        )
        .copyWith(
          headlineLarge: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineMedium: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
          titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          bodyLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          bodySmall: const TextStyle(
            fontSize: 12,
            color: BrandColors.mutedFg,
          ),
          labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        );
  }
}
