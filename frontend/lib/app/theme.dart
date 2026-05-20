import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand colour tokens from the Drivly design system v2 (dark-first).
///
/// Use these directly for bespoke colours; semantic colours
/// (`colorScheme.primary`, etc.) are wired from these in [DrivlyTheme].
class BrandColors {
  BrandColors._();

  static const Color background = Color(0xFF0B0D14); // scaffold (cool near-black)
  static const Color surface = Color(0xFF14171F); // cards (1 step above bg)
  static const Color surface2 = Color(0xFF1C2029); // nested / input fills
  static const Color surface3 = Color(0xFF252934); // hover / pressed / row hl
  static const Color foreground = Color(0xFFF5F6FA);
  static const Color mutedFg = Color(0xFF9BA0AE); // secondary text
  static const Color subtleFg = Color(0xFF6B7080); // placeholder / disabled
  static const Color primary = Color(0xFFCBF24A); // Electric Lime
  static const Color primaryFg = Color(0xFF0B0D14); // on-lime text
  static const Color primaryDim = Color(0xFF8FA833); // disabled / pressed CTA
  static const Color accent = Color(0xFFFB6F5A); // Coral
  static const Color success = Color(0xFF6FE0A1);
  static const Color successBg = Color(0xFF153026); // tonal badge bg
  static const Color warning = Color(0xFFF0C75A);
  static const Color warningBg = Color(0xFF332813);
  static const Color destructive = Color(0xFFE5604F);
  static const Color destructiveBg = Color(0xFF351A18); // error banner bg
  static const Color border = Color(0xFF262A36);
  static const Color borderStrong = Color(0xFF353A48); // handles / focus rows
}

/// Reusable gradients (hero backgrounds, CTAs, badges).
class BrandGradients {
  BrandGradients._();

  /// Splash / onboarding full-screen background.
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16213B), BrandColors.background, Color(0xFF0E1A14)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Primary CTA / balance card (lime → mint).
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFCBF24A), Color(0xFF8FE6A0)],
  );

  /// Coral → red, for live/hot badges.
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFB6F5A), Color(0xFFE5604F)],
  );
}

/// Reusable shadows. Applied manually (theme keeps elevation flat).
class BrandShadows {
  BrandShadows._();

  /// Soft dark drop for elevated cards.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10)),
  ];

  /// Lime halo behind primary CTAs / active map pins.
  static const List<BoxShadow> glow = [
    BoxShadow(
      color: Color(0x59CBF24A),
      blurRadius: 28,
      spreadRadius: -6,
      offset: Offset(0, 6),
    ),
  ];
}

/// Canonical component sizes (dp).
class Sizes {
  Sizes._();
  static const double ctaHeight = 56;
  static const double secondaryHeight = 48;
  static const double fieldHeight = 56;
  static const double bottomNavHeight = 72;
  static const double appBarHeight = 56;
  static const double icon = 24;
  static const double iconLg = 26;
  static const double avatarSm = 32;
  static const double avatar = 44;
  static const double avatarLg = 64;
}

/// Spacing scale (dp).
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

/// Corner radii scale. (`btn`/`card` kept as aliases for existing call sites.)
class Radii {
  Radii._();
  static const double xs = 8; // checkboxes, tiny chips
  static const double sm = 12; // small badges, list rows
  static const double md = 14; // text fields
  static const double lg = 18; // secondary buttons, segmented
  static const double xl = 20; // cards
  static const double xxl = 28; // primary CTA, modals, sheets
  static const double pill = 999;

  // Back-compat aliases (used across feature screens).
  static const double btn = lg; // 18 → secondary
  static const double card = xl; // 20
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
      appBarTheme: AppBarTheme(
        backgroundColor: BrandColors.background,
        foregroundColor: BrandColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: Sizes.appBarHeight,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: BrandColors.foreground,
          fontSize: 19,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BrandColors.primary,
          foregroundColor: BrandColors.primaryFg,
          disabledBackgroundColor: BrandColors.primaryDim,
          disabledForegroundColor: BrandColors.primaryFg.withValues(alpha: 0.7),
          minimumSize: const Size.fromHeight(Sizes.ctaHeight),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.xxl),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandColors.foreground,
          backgroundColor: BrandColors.surface,
          minimumSize: const Size.fromHeight(Sizes.secondaryHeight),
          side: const BorderSide(color: BrandColors.border),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BrandColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: BrandColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          side: const BorderSide(color: BrandColors.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BrandColors.surface,
        selectedColor: BrandColors.primary,
        side: const BorderSide(color: BrandColors.border),
        labelStyle:
            GoogleFonts.inter(color: BrandColors.foreground, fontSize: 13, fontWeight: FontWeight.w500),
        secondaryLabelStyle:
            GoogleFonts.inter(color: BrandColors.primaryFg, fontSize: 13, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BrandColors.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        hintStyle: GoogleFonts.inter(color: BrandColors.subtleFg),
        labelStyle: GoogleFonts.inter(color: BrandColors.mutedFg),
        floatingLabelStyle: GoogleFonts.inter(
            color: BrandColors.primary, fontWeight: FontWeight.w600),
        prefixIconColor: BrandColors.mutedFg,
        suffixIconColor: BrandColors.mutedFg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: const BorderSide(color: BrandColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: const BorderSide(color: BrandColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: const BorderSide(color: BrandColors.destructive, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide:
              const BorderSide(color: BrandColors.destructive, width: 1.8),
        ),
        errorStyle:
            GoogleFonts.inter(color: BrandColors.destructive, fontSize: 12.5),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: Sizes.bottomNavHeight,
        backgroundColor: BrandColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: BrandColors.primary.withValues(alpha: 0.18),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? BrandColors.primary : BrandColors.mutedFg,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? BrandColors.primary : BrandColors.mutedFg,
          );
        }),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xxl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: BrandColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          side: const BorderSide(color: BrandColors.border),
        ),
        titleTextStyle: GoogleFonts.spaceGrotesk(
            color: BrandColors.foreground, fontSize: 20, fontWeight: FontWeight.w700),
        contentTextStyle: GoogleFonts.inter(
            color: BrandColors.mutedFg, fontSize: 14.5, height: 1.45),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BrandColors.surface2,
        contentTextStyle: GoogleFonts.inter(color: BrandColors.foreground),
        actionTextColor: BrandColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: BrandColors.primary,
        inactiveTrackColor: BrandColors.surface2,
        thumbColor: BrandColors.primary,
        overlayColor: Color(0x26CBF24A),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? BrandColors.primaryFg
                : BrandColors.mutedFg),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? BrandColors.primary
                : BrandColors.surface2),
        trackOutlineColor:
            WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? BrandColors.primary
                : Colors.transparent),
        checkColor: WidgetStateProperty.all(BrandColors.primaryFg),
        side: const BorderSide(color: BrandColors.borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xs),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: BrandColors.foreground,
        unselectedLabelColor: BrandColors.mutedFg,
        indicatorColor: BrandColors.primary,
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      dividerTheme: const DividerThemeData(
        color: BrandColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BrandColors.primary,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    // Inter for body/labels; Space Grotesk for display/headlines/titleLarge —
    // the exact pairing from the design. (Space Grotesk maxes at w700, so the
    // spec's w800 displays use w700 — the heaviest weight the font ships.)
    final body = GoogleFonts.interTextTheme(base).apply(
      bodyColor: BrandColors.foreground,
      displayColor: BrandColors.foreground,
    );

    TextStyle grotesk(double size, FontWeight weight, double spacing) =>
        GoogleFonts.spaceGrotesk(
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
          color: BrandColors.foreground,
          height: 1.05,
        );

    TextStyle inter(double size, FontWeight weight,
            {double spacing = 0, Color? color, double? height}) =>
        GoogleFonts.inter(
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
          color: color ?? BrandColors.foreground,
          height: height,
        );

    return body.copyWith(
      displayLarge: grotesk(40, FontWeight.w700, -1.0),
      displayMedium: grotesk(34, FontWeight.w700, -0.8),
      displaySmall: grotesk(28, FontWeight.w700, -0.6),
      headlineLarge: grotesk(26, FontWeight.w700, -0.5),
      headlineMedium: grotesk(22, FontWeight.w700, -0.4),
      headlineSmall: grotesk(19, FontWeight.w600, -0.3),
      titleLarge: grotesk(17, FontWeight.w600, -0.2),
      titleMedium: inter(15.5, FontWeight.w600, spacing: -0.1),
      titleSmall: inter(13.5, FontWeight.w600, spacing: 0.1),
      bodyLarge: inter(15, FontWeight.w400, height: 1.5),
      bodyMedium: inter(14, FontWeight.w400, height: 1.45),
      bodySmall: inter(12.5, FontWeight.w400,
          color: BrandColors.mutedFg, height: 1.4),
      labelLarge: inter(14, FontWeight.w600),
      labelMedium: inter(12.5, FontWeight.w600, spacing: 0.3),
      labelSmall: inter(11, FontWeight.w700, spacing: 0.8),
    );
  }
}
