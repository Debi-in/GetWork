// ============================================================
// APP COLORS — GetWork App
// Design: Warm, Friendly, Modern, Crispy Emerald & Orange
// ============================================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary: Warm Orange Action Color ────────────────────────
  static const Color primary = Color(0xFFF57C3F);
  static const Color primaryLight = Color(0xFFFF9D66);
  static const Color primaryDark = Color(0xFFD95B1A);
  static const Color primaryContainer = Color(0xFFFFEAD9);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF421500);

  // ── Accent / Urgent Highlights ────────────────────────────────
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentLight = Color(0xFFFF8C61);
  static const Color accentDark = Color(0xFFE53935);
  static const Color accentContainer = Color(0xFFFFE3DC);
  static const Color onAccent = Color(0xFFFFFFFF);

  // ── Navigation Purple Theme ──────────────────────────────────
  static const Color navPurple = Color(0xFF5B46E6);
  static const Color navPurpleLight = Color(0xFFEEEBFF);

  // ── Background: Warm Neutral ──────────────────────────────────
  static const Color background = Color(0xFFFAF8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3EFE9);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // ── Text ─────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1F2933);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ── Status Colors ─────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successDark = Color(0xFF1D6B4A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ── Job Category Colors ──────────────────────────────────────
  static const Color categoryDelivery = Color(0xFFF57C3F);
  static const Color categoryRetail = Color(0xFF0D9488);
  static const Color categoryFood = Color(0xFFE53935);
  static const Color categoryConstruction = Color(0xFF8D6E63);
  static const Color categoryCleaning = Color(0xFF0284C7);
  static const Color categoryTech = Color(0xFF7C4DFF);
  static const Color categoryEvents = Color(0xFFD97706);

  // ── Map Marker Colors ────────────────────────────────────────
  static const Color markerDefault = Color(0xFF22C55E);
  static const Color markerUrgent = Color(0xFFF57C3F);
  static const Color markerApplied = Color(0xFF3B82F6);

  // ── Borders & Dividers ───────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // ── Shadows ──────────────────────────────────────────────────
  static const Color shadowLight = Color(0x0D000000);
  static const Color shadowMedium = Color(0x1F000000);

  // ── Reference Gradient Palettes ──────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF57C3F), Color(0xFFE05D1B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0F5132), Color(0xFF0D9488), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient urgentGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient workerBadgeGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient businessBadgeGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassOverlayGradient = LinearGradient(
    colors: [
      Color(0x38FFFFFF),
      Color(0x14FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient salaryPillGradient = LinearGradient(
    colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
