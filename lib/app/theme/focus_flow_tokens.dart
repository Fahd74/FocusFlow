import 'package:flutter/material.dart';

/// Spacing scale – 8px base unit (per DESIGN.md)
class FocusFlowSpacing {
  const FocusFlowSpacing._();

  static const xxs = 2.0;
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 40.0;
}

/// Border-radius scale (DESIGN.md: sm=0.25rem, DEFAULT=0.5rem, lg=1rem)
class FocusFlowRadius {
  const FocusFlowRadius._();

  static const none = 0.0;
  static const sm   = 4.0;   // 0.25rem
  static const md   = 8.0;   // 0.5rem  – default (buttons, cards, inputs)
  static const lg   = 12.0;  // 0.75rem
  static const xl   = 16.0;  // 1rem    – modal wrappers
  static const pill = 9999.0;
}

/// Elevation / shadow tokens (DESIGN.md: flat borders, subtle shadows)
class FocusFlowShadows {
  const FocusFlowShadows._();

  /// Default card – faint diffused lift
  static const card = [
    BoxShadow(
      color: Color(0x0F000000),  // rgba(0,0,0,0.06)
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];

  /// Hover/lifted – slightly stronger feedback
  static const lifted = [
    BoxShadow(
      color: Color(0x14334155),  // rgba(51,65,85,0.08)
      blurRadius: 12,
      spreadRadius: -2,
      offset: Offset(0, 4),
    ),
  ];

  /// Legacy alias kept for compatibility
  static const soft = card;
}

/// Icon size scale – standardized across the system
class FocusFlowIconSize {
  const FocusFlowIconSize._();

  static const sm = 14.0; // Chips, badges, small meta icons
  static const md = 20.0; // Input fields, buttons, sidebar items, list icons
  static const lg = 28.0; // Card headers, metric badges
  static const xl = 48.0; // Hero, empty states
}

/// Responsive Typography Tokens (Mobile & Desktop)
class FocusFlowTypography {
  const FocusFlowTypography._();

  // ── Mobile Mode (وضع الموبايل) ──────────────────────────────────
  /// Display / Hero (Splash & Onboarding): 28px - 32px, Bold (700) / ExtraBold (800)
  static const double mobileDisplayHeroMin = 28.0;
  static const double mobileDisplayHeroMax = 32.0;
  static const double mobileDisplayHero = 30.0;
  static const FontWeight mobileDisplayHeroWeight = FontWeight.w800; // ExtraBold (800)

  /// H1 / Main Section (App Bar & Screen titles): 22px - 24px, Bold (700) / SemiBold (600)
  static const double mobileH1Min = 22.0;
  static const double mobileH1Max = 24.0;
  static const double mobileH1 = 23.0;
  static const FontWeight mobileH1Weight = FontWeight.w700; // Bold (700)

  /// H2 / Sub-header (Cards & Section titles): 18px - 20px, SemiBold (600) / Medium (500)
  static const double mobileH2Min = 18.0;
  static const double mobileH2Max = 20.0;
  static const double mobileH2 = 19.0;
  static const FontWeight mobileH2Weight = FontWeight.w600; // SemiBold (600)

  /// Body Large (Long texts & Inputs): 16px, Regular (400) / Medium (500)
  static const double mobileBodyLarge = 16.0;
  static const FontWeight mobileBodyLargeWeight = FontWeight.w400; // Regular (400)

  /// Body Medium (Secondary description & Helper text): 14px, Regular (400)
  static const double mobileBodyMedium = 14.0;
  static const FontWeight mobileBodyMediumWeight = FontWeight.w400; // Regular (400)

  /// Caption (Dates & Bottom Nav): 12px - 13px, Regular (400) / Medium (500)
  static const double mobileCaptionMin = 12.0;
  static const double mobileCaptionMax = 13.0;
  static const double mobileCaption = 12.5;
  static const FontWeight mobileCaptionWeight = FontWeight.w500; // Medium (500)

  /// Buttons (Button texts & CTA): 14px - 16px, SemiBold (600) / Medium (500)
  static const double mobileButtonMin = 14.0;
  static const double mobileButtonMax = 16.0;
  static const double mobileButton = 15.0;
  static const FontWeight mobileButtonWeight = FontWeight.w600; // SemiBold (600)

  // ── Desktop Mode (وضع الديسكتوب) ────────────────────────────────
  /// Page Title / H1 (Main page titles & Dashboards): 32px - 40px, Bold (700) / Heavy (800)
  static const double desktopH1Min = 32.0;
  static const double desktopH1Max = 40.0;
  static const double desktopH1 = 36.0;
  static const FontWeight desktopH1Weight = FontWeight.w800; // Heavy / ExtraBold (800)

  /// H2 / Large Section (Large table titles & Widgets): 24px - 28px, Bold (700) / SemiBold (600)
  static const double desktopH2Min = 24.0;
  static const double desktopH2Max = 28.0;
  static const double desktopH2 = 26.0;
  static const FontWeight desktopH2Weight = FontWeight.w700; // Bold (700)

  /// H3 / Sub-header (Modals & Cards): 18px - 20px, SemiBold (600) / Medium (500)
  static const double desktopH3Min = 18.0;
  static const double desktopH3Max = 20.0;
  static const double desktopH3 = 19.0;
  static const FontWeight desktopH3Weight = FontWeight.w600; // SemiBold (600)

  /// Body Large (Dense texts & Articles): 16px, Regular (400)
  static const double desktopBodyLarge = 16.0;
  static const FontWeight desktopBodyLargeWeight = FontWeight.w400; // Regular (400)

  /// Body Medium (Tables, Sidebar & Forms): 14px, Regular (400)
  static const double desktopBodyMedium = 14.0;
  static const FontWeight desktopBodyMediumWeight = FontWeight.w400; // Regular (400)

  /// Caption / Metadata (Explanatory notes & Data details): 12px - 13px, Regular (400) / Medium (500)
  static const double desktopCaptionMin = 12.0;
  static const double desktopCaptionMax = 13.0;
  static const double desktopCaption = 12.5;
  static const FontWeight desktopCaptionWeight = FontWeight.w400; // Regular (400)

  /// Buttons (Buttons & Menu navigation): 14px - 16px, Medium (500) / SemiBold (600)
  static const double desktopButtonMin = 14.0;
  static const double desktopButtonMax = 16.0;
  static const double desktopButton = 15.0;
  static const FontWeight desktopButtonWeight = FontWeight.w600; // SemiBold (600)
}


