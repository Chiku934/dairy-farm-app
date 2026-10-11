import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = AppTypography.textTheme(AppColors.textMain);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary700,
        onPrimary: AppColors.textOnDark,
        primaryContainer: AppColors.primary50,
        onPrimaryContainer: AppColors.primary900,
        secondary: AppColors.primary800,
        onSecondary: AppColors.textOnDark,
        secondaryContainer: AppColors.mintSurface,
        onSecondaryContainer: AppColors.primary900,
        surface: AppColors.cardSurface,
        onSurface: AppColors.textMain,
        error: AppColors.statusDanger,
        onError: Colors.white,
        errorContainer: AppColors.statusDangerSurface,
        onErrorContainer: AppColors.statusDanger,
        outline: AppColors.borderSubtle,
        outlineVariant: AppColors.borderStrong,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.primary900),
        actionsIconTheme: const IconThemeData(color: AppColors.textSecondary),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.textMain,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedMd,
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary700,
          foregroundColor: AppColors.textOnDark,
          disabledBackgroundColor: AppColors.surfaceSubtle,
          disabledForegroundColor: AppColors.textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.roundedSm,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          disabledForegroundColor: AppColors.textDisabled,
          side: const BorderSide(color: AppColors.borderStrong, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.roundedSm,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary700,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.roundedSm,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textDisabled),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        helperStyle: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.statusDanger),
        border: OutlineInputBorder(
          borderRadius: AppRadius.roundedSm,
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedSm,
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedSm,
          borderSide: const BorderSide(color: AppColors.primary700, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedSm,
          borderSide: const BorderSide(color: AppColors.statusDanger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedSm,
          borderSide: const BorderSide(color: AppColors.statusDanger, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedSm,
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceNeutral,
        disabledColor: AppColors.surfaceSubtle,
        selectedColor: AppColors.primary100,
        secondarySelectedColor: AppColors.primary200,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedFull,
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        labelStyle: textTheme.labelMedium,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedLg,
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.sheetTop,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary900,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedSm,
        ),
      ),
    );
  }
}
