import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized typography definitions for Dairy Farm App.
/// Built with Inter / Roboto for crisp, high-readability in field and daylight conditions.
class AppTypography {
  static TextTheme textTheme([Color defaultColor = AppColors.textMain]) {
    final base = GoogleFonts.interTextTheme();

    return base.copyWith(
      // Headlines
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.5,
        color: defaultColor,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.3,
        color: defaultColor,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: defaultColor,
      ),

      // Titles
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: defaultColor,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: defaultColor,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: defaultColor,
      ),

      // Body Text
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: defaultColor,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.textSecondary,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textMuted,
      ),

      // Labels & Buttons
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: defaultColor,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: AppColors.textSecondary,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: AppColors.textMuted,
      ),
    );
  }

  // Convenient static getters for standard typography
  static TextStyle get headlineLarge => textTheme().headlineLarge!;
  static TextStyle get headlineMedium => textTheme().headlineMedium!;
  static TextStyle get headlineSmall => textTheme().headlineSmall!;
  static TextStyle get titleLarge => textTheme().titleLarge!;
  static TextStyle get titleMedium => textTheme().titleMedium!;
  static TextStyle get titleSmall => textTheme().titleSmall!;
  static TextStyle get bodyLarge => textTheme().bodyLarge!;
  static TextStyle get bodyMedium => textTheme().bodyMedium!;
  static TextStyle get bodySmall => textTheme().bodySmall!;
  static TextStyle get labelLarge => textTheme().labelLarge!;
  static TextStyle get labelMedium => textTheme().labelMedium!;
  static TextStyle get labelSmall => textTheme().labelSmall!;

  // Hero Metric typography (for farm counters, milk yields, revenue)
  static TextStyle metricHero({Color color = AppColors.textMain}) {
    return GoogleFonts.inter(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.5,
      color: color,
    );
  }

  static TextStyle metricMedium({Color color = AppColors.textMain}) {
    return GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.3,
      color: color,
    );
  }

  static TextStyle metricSmall({Color color = AppColors.textMain}) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: color,
    );
  }

  // Section Header uppercase label
  static TextStyle sectionHeader({Color color = AppColors.textMuted}) {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: color,
    );
  }
}
