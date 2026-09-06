import 'package:flutter/material.dart';

import 'focus_flow_colors.dart';
import 'focus_flow_tokens.dart';

/// FocusFlow Theme – aligned with "Network Flow Aesthetic" (DESIGN.md)
///
/// Color system: Connectivity Blue (#005691) as primary/brand.
/// Typography: Open Sans (body + labels) – loaded as local asset fonts.
/// Shape: 8px default border-radius (DESIGN.md DEFAULT = 0.5rem).
class FocusFlowTheme {
  const FocusFlowTheme._();

  static TextTheme textTheme({bool isDesktop = false}) {
    return TextTheme(
      // ── Display / Hero (Splash & Onboarding): Mobile 28-32px (30px 800), Desktop 32-40px (36px 800)
      displayLarge: TextStyle(
        color: FocusFlowColors.ink,
        fontSize: isDesktop ? FocusFlowTypography.desktopH1 : FocusFlowTypography.mobileDisplayHero,
        fontWeight: isDesktop ? FocusFlowTypography.desktopH1Weight : FocusFlowTypography.mobileDisplayHeroWeight,
        height: 1.1,
        letterSpacing: -0.5,
      ),
      // ── H1 / Page Title: Mobile 22-24px (23px 700), Desktop 32-40px (36px 800)
      headlineLarge: TextStyle(
        color: FocusFlowColors.ink,
        fontSize: isDesktop ? FocusFlowTypography.desktopH1 : FocusFlowTypography.mobileH1,
        fontWeight: isDesktop ? FocusFlowTypography.desktopH1Weight : FocusFlowTypography.mobileH1Weight,
        height: 1.25,
        letterSpacing: -0.32,
      ),
      // ── H2 / Main Section: Mobile 18-20px (19px 600), Desktop 24-28px (26px 700)
      headlineMedium: TextStyle(
        color: FocusFlowColors.ink,
        fontSize: isDesktop ? FocusFlowTypography.desktopH2 : FocusFlowTypography.mobileH2,
        fontWeight: isDesktop ? FocusFlowTypography.desktopH2Weight : FocusFlowTypography.mobileH2Weight,
        height: 1.33,
      ),
      // ── H3 / Sub-header: Mobile 18-20px (19px 600), Desktop 18-20px (19px 600)
      headlineSmall: TextStyle(
        color: FocusFlowColors.ink,
        fontSize: isDesktop ? FocusFlowTypography.desktopH3 : FocusFlowTypography.mobileH2,
        fontWeight: isDesktop ? FocusFlowTypography.desktopH3Weight : FocusFlowTypography.mobileH2Weight,
        height: 1.4,
      ),
      // ── Titles ─────────────────────────────────────────────────
      titleLarge: TextStyle(
        color: FocusFlowColors.ink,
        fontSize: isDesktop ? FocusFlowTypography.desktopH3 : FocusFlowTypography.mobileH2,
        fontWeight: isDesktop ? FocusFlowTypography.desktopH3Weight : FocusFlowTypography.mobileH2Weight,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        color: FocusFlowColors.ink,
        fontSize: isDesktop ? FocusFlowTypography.desktopBodyLarge : FocusFlowTypography.mobileBodyLarge,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        color: FocusFlowColors.ink,
        fontSize: isDesktop ? FocusFlowTypography.desktopBodyMedium : FocusFlowTypography.mobileBodyMedium,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      // ── Body Large: 16px 400 ────────────────────────────────────
      bodyLarge: TextStyle(
        color: FocusFlowColors.muted,
        fontSize: isDesktop ? FocusFlowTypography.desktopBodyLarge : FocusFlowTypography.mobileBodyLarge,
        fontWeight: isDesktop ? FocusFlowTypography.desktopBodyLargeWeight : FocusFlowTypography.mobileBodyLargeWeight,
        height: 1.6,
        letterSpacing: 0,
      ),
      // ── Body Medium: 14px 400 ───────────────────────────────────
      bodyMedium: TextStyle(
        color: FocusFlowColors.muted,
        fontSize: isDesktop ? FocusFlowTypography.desktopBodyMedium : FocusFlowTypography.mobileBodyMedium,
        fontWeight: isDesktop ? FocusFlowTypography.desktopBodyMediumWeight : FocusFlowTypography.mobileBodyMediumWeight,
        height: 1.5,
        letterSpacing: 0,
      ),
      // ── Caption / Body Small: 12-13px (12.5px 400/500) ───────────
      bodySmall: TextStyle(
        color: FocusFlowColors.muted,
        fontSize: isDesktop ? FocusFlowTypography.desktopCaption : FocusFlowTypography.mobileCaption,
        fontWeight: isDesktop ? FocusFlowTypography.desktopCaptionWeight : FocusFlowTypography.mobileCaptionWeight,
        height: 1.4,
        letterSpacing: 0,
      ),
      // ── Buttons / Labels: 14-16px (15px 600/500) ─────────────────
      labelLarge: TextStyle(
        color: FocusFlowColors.ink,
        fontSize: isDesktop ? FocusFlowTypography.desktopButton : FocusFlowTypography.mobileButton,
        fontWeight: isDesktop ? FocusFlowTypography.desktopButtonWeight : FocusFlowTypography.mobileButtonWeight,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        color: FocusFlowColors.muted,
        fontSize: isDesktop ? FocusFlowTypography.desktopCaption : FocusFlowTypography.mobileCaption,
        fontWeight: isDesktop ? FocusFlowTypography.desktopCaptionWeight : FocusFlowTypography.mobileCaptionWeight,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        color: FocusFlowColors.quiet,
        fontSize: isDesktop ? FocusFlowTypography.desktopCaption : FocusFlowTypography.mobileCaption,
        fontWeight: isDesktop ? FocusFlowTypography.desktopCaptionWeight : FocusFlowTypography.mobileCaptionWeight,
        letterSpacing: 0.5,
      ),
    );
  }

  static ThemeData mobile() => light(isDesktop: false);
  static ThemeData desktop() => light(isDesktop: true);

  static ThemeData light({bool isDesktop = false}) {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      // Primary – Connectivity Blue
      primary: FocusFlowColors.brand,
      onPrimary: Colors.white,
      primaryContainer: FocusFlowColors.brandSoft,
      onPrimaryContainer: FocusFlowColors.brandHover,
      // Secondary
      secondary: FocusFlowColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: FocusFlowColors.secondaryContainer,
      onSecondaryContainer: FocusFlowColors.onSecondaryContainer,
      // Tertiary (neutral)
      tertiary: FocusFlowColors.quiet,
      onTertiary: Colors.white,
      tertiaryContainer: FocusFlowColors.surfaceMid,
      onTertiaryContainer: FocusFlowColors.ink,
      // Surface layers
      surface: FocusFlowColors.surface,
      onSurface: FocusFlowColors.ink,
      surfaceContainerLowest: FocusFlowColors.surface,
      surfaceContainerLow: FocusFlowColors.surfaceLow,
      surfaceContainer: FocusFlowColors.surfaceMid,
      surfaceContainerHigh: FocusFlowColors.surfaceHigh,
      surfaceContainerHighest: FocusFlowColors.surfaceHigh,
      // Semantic
      error: FocusFlowColors.danger,
      onError: Colors.white,
      errorContainer: FocusFlowColors.dangerSoft,
      onErrorContainer: FocusFlowColors.dangerDeep,
      // Outline
      outline: FocusFlowColors.borderStrong,
      outlineVariant: FocusFlowColors.border,
    );

    final typography = textTheme(isDesktop: isDesktop);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      splashFactory: InkRipple.splashFactory,
      scaffoldBackgroundColor: FocusFlowColors.canvas,
      iconTheme: const IconThemeData(
        color: FocusFlowColors.muted,
        size: FocusFlowIconSize.md,
      ),
      // Open Sans loaded as asset font (registered in pubspec.yaml)
      fontFamily: 'OpenSans',

      textTheme: typography,

      // ── Cards ────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: FocusFlowColors.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FocusFlowRadius.md),
          side: const BorderSide(color: FocusFlowColors.border),
        ),
      ),

      // ── AppBar ───────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: FocusFlowColors.canvas,
        foregroundColor: FocusFlowColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'OpenSans',
          color: FocusFlowColors.ink,
          fontSize: isDesktop ? FocusFlowTypography.desktopH2 : FocusFlowTypography.mobileH1,
          fontWeight: isDesktop ? FocusFlowTypography.desktopH2Weight : FocusFlowTypography.mobileH1Weight,
        ),
      ),

      // ── Inputs ───────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FocusFlowColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        // Labels always ABOVE (per DESIGN.md)
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
          color: FocusFlowColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: FocusFlowColors.quiet,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FocusFlowRadius.md),
          borderSide: const BorderSide(color: FocusFlowColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FocusFlowRadius.md),
          borderSide: const BorderSide(color: FocusFlowColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FocusFlowRadius.md),
          borderSide: const BorderSide(
            color: FocusFlowColors.brand,
            width: 2, // 2px focus ring per DESIGN.md
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FocusFlowRadius.md),
          borderSide: const BorderSide(color: FocusFlowColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FocusFlowRadius.md),
          borderSide: const BorderSide(color: FocusFlowColors.danger, width: 2),
        ),
      ),

      // ── Buttons ──────────────────────────────────────────────────
      // Primary: Connectivity Blue bg + white text (DESIGN.md)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FocusFlowColors.brand,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
          ),
          minimumSize: const Size(48, 46),
          elevation: 0,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return FocusFlowColors.brandHover.withValues(alpha: 0.15);
            }
            if (states.contains(WidgetState.pressed)) {
              return FocusFlowColors.brandHover.withValues(alpha: 0.25);
            }
            return null;
          }),
        ),
      ),
      // Secondary: transparent + blue border (DESIGN.md)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FocusFlowColors.brand,
          side: const BorderSide(color: FocusFlowColors.brand, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
          ),
          minimumSize: const Size(48, 46),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return FocusFlowColors.brand.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.pressed)) {
              return FocusFlowColors.brand.withValues(alpha: 0.16);
            }
            return null;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FocusFlowColors.brand,
          textStyle: const TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Chips ────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: FocusFlowColors.surfaceMid,
        selectedColor: FocusFlowColors.brandSoft,
        disabledColor: FocusFlowColors.surfaceHigh,
        labelStyle: const TextStyle(
          color: FocusFlowColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FocusFlowRadius.pill),
        ),
        side: BorderSide.none,
      ),

      // ── Bottom Navigation ─────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: FocusFlowColors.surface,
        indicatorColor: FocusFlowColors.brandSoft,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? FocusFlowColors.brand
                : FocusFlowColors.muted,
          ),
        ),
      ),

      // ── Divider ───────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: FocusFlowColors.border,
        thickness: 1,
        space: 0,
      ),

      // ── Progress Indicator ────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FocusFlowColors.brand,
      ),
    );
  }
}
