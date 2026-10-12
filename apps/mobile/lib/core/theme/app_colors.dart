import 'package:flutter/material.dart';

/// Design tokens for Dairy Farm Management System.
/// Follows commercial farm-management aesthetic:
/// warm white surfaces, deep forest green brand anchors, emerald & mint accents,
/// charcoal typography, and subtle borders.
class AppColors {
  // Primary Forest Green Palette (Brand Anchor)
  static const Color primary950 = Color(0xFF092617);
  static const Color primary900 = Color(0xFF0F3923); // Active navigation & hero containers
  static const Color primary800 = Color(0xFF165A36); // Headers & deep accents
  static const Color primary700 = Color(0xFF1B6E42); // Primary buttons & brand focus
  static const Color primary600 = Color(0xFF238652); // Active tabs & interactive hover
  static const Color primary500 = Color(0xFF2E9E66); // Mid green
  static const Color primary400 = Color(0xFF48BB78); // Lighter accent
  static const Color primary200 = Color(0xFFBBF7D0); // Outline badge borders
  static const Color primary100 = Color(0xFFDCFCE7); // Light badge fills
  static const Color primary50 = Color(0xFFF0FDF4);  // Subtle green tint surfaces

  // Semantic Aliases
  static const Color primary = primary700;
  static const Color secondary = primary500;
  static const Color danger = statusDanger;
  static const Color surface = cardSurface;

  // Warm White & Soft Neutral Canvas
  static const Color background = Color(0xFFF7F8F5);     // Warm white screen background
  static const Color surfaceWarm = Color(0xFFFAFAF7);    // Slightly elevated warm container
  static const Color cardSurface = Color(0xFFFFFFFF);    // Primary card & dialog surface
  static const Color surfaceNeutral = Color(0xFFF2F4ED); // Table headers, chip backgrounds
  static const Color surfaceSubtle = Color(0xFFECEFE8);  // Inset input fills
  static const Color borderSubtle = Color(0xFFE2E6DC);   // Card borders & input outlines
  static const Color borderStrong = Color(0xFFCBD2C4);   // Active outlines

  // Charcoal Typography
  static const Color textMain = Color(0xFF19241E);       // Dark charcoal with deep undertone
  static const Color textSecondary = Color(0xFF38433C);  // Secondary body & headings
  static const Color textMuted = Color(0xFF637066);      // Captions, helper labels, icons
  static const Color textDisabled = Color(0xFF9BA69E);   // Disabled buttons & placeholder
  static const Color textOnDark = Color(0xFFFFFFFF);     // Text on forest green surfaces

  // Emerald & Mint Accents
  static const Color emerald = Color(0xFF059669);
  static const Color mint = Color(0xFF10B981);
  static const Color mintLight = Color(0xFFA7F3D0);
  static const Color mintSurface = Color(0xFFECFDF5);

  // Semantic Status Tokens
  // Success (Accepted, Active, Eligible, Normal)
  static const Color statusSuccess = Color(0xFF15803D);
  static const Color statusSuccessSurface = Color(0xFFF0FDF4);
  static const Color statusSuccessBorder = Color(0xFFBBF7D0);

  // Warning (Hold, Pending, Low Stock, Due Alert)
  static const Color statusWarning = Color(0xFFB45309);
  static const Color statusWarningSurface = Color(0xFFFFFBEB);
  static const Color statusWarningBorder = Color(0xFFFDE68A);

  // Danger (Rejected, Withheld, Expired, Out of Stock)
  static const Color statusDanger = Color(0xFFB91C1C);
  static const Color statusDangerSurface = Color(0xFFFEF2F2);
  static const Color statusDangerBorder = Color(0xFFFECACA);

  // Info (Processing, Routine, Transit)
  static const Color statusInfo = Color(0xFF0369A1);
  static const Color statusInfoSurface = Color(0xFFF0F9FF);
  static const Color statusInfoBorder = Color(0xFFBAE6FD);

  // Neutral Status (Dry, Inactive, Archived)
  static const Color statusNeutral = Color(0xFF4B5563);
  static const Color statusNeutralSurface = Color(0xFFF3F4F6);
  static const Color statusNeutralBorder = Color(0xFFE5E7EB);

  // Restrained Gradients
  static const LinearGradient gradientForest = LinearGradient(
    colors: [primary900, primary800],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientForestAccent = LinearGradient(
    colors: [primary800, primary600],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientEmeraldMint = LinearGradient(
    colors: [emerald, mint],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient gradientSubtleWarm = LinearGradient(
    colors: [cardSurface, surfaceWarm],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Convenience Aliases for Design System Compatibility
  static const Color textPrimary = textMain;
  static const Color neutralBorder = borderSubtle;
  static const Color statusError = statusDanger;
  static const Color warningBg = statusWarningSurface;
  static const Color neutral100 = surfaceSubtle;
  static const Color neutral500 = textMuted;
  static const Color neutral600 = textSecondary;
  static const Color neutral700 = textSecondary;
  static const Color accentEmerald = emerald;
  static const Color accentMint = mint;
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color success = statusSuccess;
  static const Color error = statusDanger;
  static const Color warning = statusWarning;
  static const Color info = statusInfo;
  static const Color border = borderSubtle;
  static const Color neutral50 = surfaceWarm;
  static const Color neutral200 = borderSubtle;
  static const Color neutral400 = textMuted;
  static const Color accent = mint;
  static const Color neutralSecondary = Color(0xFF637066);
  static const Color neutralLight = Color(0xFFF2F4ED);
}

