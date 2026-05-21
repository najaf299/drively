import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand colour tokens — drivly Flutter Build Spec v2 §1.1 (dark-first).
///
/// Hex values are taken verbatim from the spec table. Never hardcode hex in
/// widgets — use these tokens (Acceptance Checklist §9). Tonal background pairs
/// (e.g. [successBg]) MUST be used with their matching foreground.
class BrandColors {
  BrandColors._();

  static const Color background = Color(0xFF0B0D14); // scaffold
  static const Color surface = Color(0xFF14171F); // cards, sheets, list tiles
  static const Color surface2 = Color(0xFF1B1F2A); // input fill, chips
  static const Color surface3 = Color(0xFF242936); // hover/pressed, elevated
  static const Color border = Color(0xFF262A36); // hairlines, dividers, outline
  static const Color borderStrong = Color(0xFF3A4051); // focus, segmented
  static const Color foreground = Color(0xFFF4F5F7); // primary text/icons
  static const Color mutedFg = Color(0xFF8A8F9C); // secondary text, helper
  static const Color subtleFg = Color(0xFF5F6472); // disabled, tertiary
  static const Color primary = Color(0xFFCBF24A); // lime brand
  static const Color primaryFg = Color(0xFF0B0D14); // on-primary (near-black)
  static const Color primaryGlow = Color(0xFFE4FF7A); // hover/pressed, glow
  static const Color accent = Color(0xFF7C5CFF); // premium tier, host charts
  static const Color success = Color(0xFF22C55E);
  static const Color successBg = Color(0xFF0F2A1A);
  static const Color warning = Color(0xFFFFB020);
  static const Color warningBg = Color(0xFF2A1F0A);
  static const Color destructive = Color(0xFFFF5A5F);
  static const Color destructiveBg = Color(0xFF2A0F11);
  static const Color info = Color(0xFF3FA9FF); // toasts, route polyline
  static const Color overlay = Color(0xFF000000); // modal scrim @60%
  static const Color heroGlow = Color(0xFF3A63B8); // top light-glow on auth bg

  /// Back-compat: dim lime for legacy call sites (disabled now uses surface2).
  static const Color primaryDim = Color(0xFF8FA833);
}

/// Reusable gradients (hero backgrounds, balance/earnings cards, premium).
class BrandGradients {
  BrandGradients._();

  /// Splash / onboarding full-screen background.
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16213B), BrandColors.background, Color(0xFF0E1A14)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Lime CTA / highlight gradient.
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BrandColors.primaryGlow, BrandColors.primary],
  );

  /// Wallet/earnings hero — surface → surface2 (spec §4.4).
  static const LinearGradient surfaceCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BrandColors.surface, BrandColors.surface2],
  );

  /// Premium / accent (purple) gradient — host insights, premium tier.
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9B85FF), BrandColors.accent],
  );
}

/// Reusable shadows — spec §1.3 (applied manually; theme keeps elevation flat).
class BrandShadows {
  BrandShadows._();

  /// cardShadow: 0 8 24 rgba(0,0,0,.35).
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x59000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// limeGlow: 0 12 40 rgba(203,242,74,.25).
  static const List<BoxShadow> glow = [
    BoxShadow(color: Color(0x40CBF24A), blurRadius: 40, offset: Offset(0, 12)),
  ];
}

/// Canonical component sizes (dp) — spec §2.
class Sizes {
  Sizes._();
  static const double ctaHeight = 56; // PrimaryButton
  static const double secondaryHeight = 52; // tonal / outlined
  static const double socialHeight = 56; // OAuth row
  static const double fieldHeight = 56;
  static const double searchBar = 52; // SearchBar pill
  static const double filterChip = 36;
  static const double bottomNavHeight = 72;
  static const double appBarHeight = 56;
  static const double iconRoundButton = 44; // back/share/favorite
  static const double icon = 24;
  static const double iconLg = 26;
  static const double iconSm = 20;
  static const double avatarSm = 32; // AvatarStack
  static const double avatar = 44;
  static const double avatarMd = 48; // host row, contact icons
  static const double avatarLg = 64;
  static const double avatarXl = 96; // profile header
}

/// Spacing scale (dp) — spec §1.3.
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
  static const double x12 = 48;
  static const double x16 = 64;
}

/// Corner radii scale — spec §1.3.
class Radii {
  Radii._();
  static const double xs = 8; // checkboxes, tiny chips
  static const double sm = 12; // small badges, list rows
  static const double md = 16; // text fields (input radius)
  static const double lg = 20; // cards (card radius)
  static const double xl = 24; // dialogs, large cards
  static const double xxl = 28; // bottom sheets, modals
  static const double pill = 999; // CTA — always full pill

  // Back-compat aliases (used across feature screens).
  static const double btn = lg; // 20 → secondary buttons
  static const double card = lg; // 20 → card radius
}

/// Font helpers for sizes outside the ramp (oversized auth headlines, codes).
class BrandText {
  BrandText._();

  /// Space Grotesk display — for hero wordmarks/headlines larger than the ramp.
  static TextStyle display({
    double size = 48,
    FontWeight weight = FontWeight.w700,
    Color color = BrandColors.foreground,
    double spacing = -1.0,
    double height = 1.02,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing,
        height: height,
      );

  /// JetBrains Mono — OTP digits, license plate, booking ID (spec §1.2).
  static TextStyle mono({
    double size = 22,
    FontWeight weight = FontWeight.w600,
    Color color = BrandColors.foreground,
    double spacing = 0,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing,
      );
}

class DrivlyTheme {
  DrivlyTheme._();

  static const _scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: BrandColors.primary,
    onPrimary: BrandColors.primaryFg,
    secondary: BrandColors.accent,
    onSecondary: Colors.white,
    tertiary: BrandColors.info,
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
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      // PrimaryButton — full pill, h56, primary/primaryFg, disabled surface2.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BrandColors.primary,
          foregroundColor: BrandColors.primaryFg,
          disabledBackgroundColor: BrandColors.surface2,
          disabledForegroundColor: BrandColors.subtleFg,
          minimumSize: const Size.fromHeight(Sizes.ctaHeight),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      // Tonal / outlined — surface2 fill, border, pill.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandColors.foreground,
          backgroundColor: BrandColors.surface2,
          minimumSize: const Size.fromHeight(Sizes.secondaryHeight),
          side: const BorderSide(color: BrandColors.border),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BrandColors.primary,
          textStyle:
              GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: BrandColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),
      // FilterChip — pill 36h, surface2/border, selected primary/primaryFg.
      chipTheme: ChipThemeData(
        backgroundColor: BrandColors.surface2,
        selectedColor: BrandColors.primary,
        side: const BorderSide(color: BrandColors.border),
        labelStyle: GoogleFonts.inter(
            color: BrandColors.foreground,
            fontSize: 13,
            fontWeight: FontWeight.w500),
        secondaryLabelStyle: GoogleFonts.inter(
            color: BrandColors.primaryFg,
            fontSize: 13,
            fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: const StadiumBorder(),
      ),
      // BrandTextField — surface2 fill, radius 16, focus 1.6 primary, pad 16/14.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BrandColors.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: BrandColors.subtleFg),
        labelStyle: GoogleFonts.inter(
            color: BrandColors.mutedFg, fontWeight: FontWeight.w500),
        floatingLabelStyle: GoogleFonts.inter(
            color: BrandColors.primary, fontWeight: FontWeight.w600),
        helperStyle: GoogleFonts.inter(
            color: BrandColors.mutedFg, fontSize: 12),
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
          borderSide:
              const BorderSide(color: BrandColors.destructive, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide:
              const BorderSide(color: BrandColors.destructive, width: 1.8),
        ),
        errorStyle:
            GoogleFonts.inter(color: BrandColors.destructive, fontSize: 12),
      ),
      // BottomNavBar — M3, h72, surface, indicator primary/15.
      navigationBarTheme: NavigationBarThemeData(
        height: Sizes.bottomNavHeight,
        backgroundColor: BrandColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: BrandColors.primary.withValues(alpha: 0.15),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: Sizes.icon,
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
      // BottomSheetShell — surface, top radius 28.
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: BrandColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xxl)),
        ),
      ),
      // ConfirmDialog — surface, radius 24.
      dialogTheme: DialogThemeData(
        backgroundColor: BrandColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
        titleTextStyle: GoogleFonts.spaceGrotesk(
            color: BrandColors.foreground,
            fontSize: 20,
            fontWeight: FontWeight.w600),
        contentTextStyle: GoogleFonts.inter(
            color: BrandColors.mutedFg, fontSize: 14, height: 1.45),
      ),
      // BrandSnackbar — floating, radius 16.
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
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
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
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
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

  /// Type ramp — spec §1.2. Space Grotesk for h1–h4 (display/headline/title),
  /// Inter for body/labels/buttons. Sizes/heights/weights are verbatim.
  static TextTheme _textTheme(TextTheme base) {
    final body = GoogleFonts.interTextTheme(base).apply(
      bodyColor: BrandColors.foreground,
      displayColor: BrandColors.foreground,
    );

    TextStyle grotesk(double size, double lineHeight, FontWeight weight,
            double spacing,
            {Color color = BrandColors.foreground}) =>
        GoogleFonts.spaceGrotesk(
          fontSize: size,
          height: lineHeight / size,
          fontWeight: weight,
          letterSpacing: spacing,
          color: color,
        );

    TextStyle inter(double size, double lineHeight, FontWeight weight,
            {double spacing = 0, Color? color}) =>
        GoogleFonts.inter(
          fontSize: size,
          height: lineHeight / size,
          fontWeight: weight,
          letterSpacing: spacing,
          color: color ?? BrandColors.foreground,
        );

    return body.copyWith(
      // h1 / displayLarge — 32 / 38 · w700 · -0.5
      displayLarge: grotesk(32, 38, FontWeight.w700, -0.5),
      // h2 / displayMedium — 26 / 32 · w700 · -0.4
      displayMedium: grotesk(26, 32, FontWeight.w700, -0.4),
      // (interp) displaySmall — used for big success/celebration titles
      displaySmall: grotesk(22, 28, FontWeight.w700, -0.3),
      // (interp) headlineLarge — trip timers / large numerics
      headlineLarge: grotesk(24, 30, FontWeight.w700, -0.3),
      // (interp) headlineMedium — sticky-bar prices, section totals
      headlineMedium: grotesk(20, 26, FontWeight.w700, -0.2),
      // h3 / headlineSmall — 20 / 26 · w600 · -0.2
      headlineSmall: grotesk(20, 26, FontWeight.w600, -0.2),
      // h4 / titleLarge — 17 / 22 · w600 · 0
      titleLarge: grotesk(17, 22, FontWeight.w600, 0),
      // titleMedium — card prices / emphasised body
      titleMedium: inter(15, 20, FontWeight.w600, spacing: -0.1),
      titleSmall: inter(13, 18, FontWeight.w600, spacing: 0.1),
      // bodyLarge — 15 / 22 · w400
      bodyLarge: inter(15, 22, FontWeight.w400),
      // bodyMedium — 14 / 20 · w400 (default Text)
      bodyMedium: inter(14, 20, FontWeight.w400),
      // bodySmall / caption — 12 / 16 · w500 · mutedFg · 0.2
      bodySmall: inter(12, 16, FontWeight.w500,
          spacing: 0.2, color: BrandColors.mutedFg),
      // labelLarge / button — 15 / 18 · w600 · 0.2
      labelLarge: inter(15, 18, FontWeight.w600, spacing: 0.2),
      labelMedium: inter(12, 16, FontWeight.w600, spacing: 0.3),
      // overline — 11 / 14 · w700 · 1.2 (UPPERCASE applied at call site)
      labelSmall: inter(11, 14, FontWeight.w700,
          spacing: 1.2, color: BrandColors.mutedFg),
    );
  }
}
