import 'package:flutter/material.dart';

/// Design tokens derived from DESIGN.md – "Network Flow Aesthetic"
/// Primary: Connectivity Blue (#005691)
class FocusFlowColors {
  const FocusFlowColors._();

  // ── Primary / Brand ────────────────────────────────────────────
  /// Connectivity Blue – primary actions, active states, CTAs
  static const brand = Color(0xFF005691);

  /// Darker blue – hover / pressed states
  static const brandHover = Color(0xFF003E6B);

  /// Light blue container – selected chip bg, subtle highlights
  static const brandSoft = Color(0xFFD1E4FF);

  /// Brightest blue variant – inverse-primary, progress indicators
  static const brandLight = Color(0xFF9ECAFF);

  // ── Secondary (unified with primary in this design system) ─────
  static const secondary = Color(0xFF1A619D);
  static const secondaryContainer = Color(0xFF83BDFE);
  static const onSecondaryContainer = Color(0xFF004C80);

  // ── Surface layers (bottom → top) ──────────────────────────────
  static const canvas = Color(0xFFFAF9F9);          // background / scaffold
  static const surface = Color(0xFFFFFFFF);          // surface-container-lowest
  static const surfaceLow = Color(0xFFF4F3F3);       // surface-container-low (sidebar)
  static const surfaceMid = Color(0xFFEEEEEE);       // surface-container
  static const surfaceHigh = Color(0xFFE8E8E8);      // surface-container-high
  static const surfaceNeutral = Color(0xFFF1F4F9);   // subtle neutral badge/chip background
  static const surfaceHighlight = Color(0xFFF7F9FC); // subtle stat tile background
  static const progressTrack = Color(0xFFE3E7EE);    // progress bar track background

  // ── Text ───────────────────────────────────────────────────────
  static const ink = Color(0xFF1A1C1C);              // on-surface (primary text)
  static const muted = Color(0xFF414750);            // on-surface-variant
  static const quiet = Color(0xFF727781);            // outline / subtle text
  static const inverseSurface = Color(0xFF2F3131);   // dark surface for contrast

  // ── Borders & Dividers ─────────────────────────────────────────
  static const border = Color(0xFFC1C7D1);           // outline-variant
  static const borderStrong = Color(0xFF727781);     // outline

  // ── Semantic ───────────────────────────────────────────────────
  static const success = Color(0xFF00C853);          // electric green – status only
  static const successSoft = Color(0xFFE8F7EE);
  static const warning = Color(0xFFFFA500);          // warm orange
  static const warningSoft = Color(0xFFFFF4D6);
  static const danger = Color(0xFFBA1A1A);           // error (DESIGN.md)
  static const dangerSoft = Color(0xFFFFDAD6);       // error-container
  static const dangerDeep = Color(0xFF93000A);       // error text on container

  // ── Goal type color palette ────────────────────────────────────
  static const goalTypeChoices = <Color>[
    Color(0xFF005691), // Connectivity Blue – primary
    Color(0xFF1A619D), // Secondary blue
    Color(0xFF00897B), // Teal
    Color(0xFF43A047), // Green
    Color(0xFF7CB342), // Light green
    Color(0xFFFFA500), // Orange
    Color(0xFFF4511E), // Deep orange
    Color(0xFFE53935), // Red
    Color(0xFF8E24AA), // Purple
    Color(0xFF546E7A), // Blue grey
  ];
}
