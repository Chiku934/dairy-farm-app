import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  destructive,
  text,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.outline;

  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.destructive;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = isEnabled ? AppColors.primary700 : AppColors.surfaceSubtle;
        fg = isEnabled ? Colors.white : AppColors.textDisabled;
        break;
      case AppButtonVariant.secondary:
        bg = isEnabled ? AppColors.primary50 : AppColors.surfaceSubtle;
        fg = isEnabled ? AppColors.primary800 : AppColors.textDisabled;
        border = BorderSide(
          color: isEnabled ? AppColors.primary200 : AppColors.borderSubtle,
        );
        break;
      case AppButtonVariant.outline:
        bg = isEnabled ? AppColors.cardSurface : AppColors.surfaceSubtle;
        fg = isEnabled ? AppColors.textSecondary : AppColors.textDisabled;
        border = BorderSide(
          color: isEnabled ? AppColors.borderStrong : AppColors.borderSubtle,
        );
        break;
      case AppButtonVariant.destructive:
        bg = isEnabled ? AppColors.statusDanger : AppColors.surfaceSubtle;
        fg = isEnabled ? Colors.white : AppColors.textDisabled;
        break;
      case AppButtonVariant.text:
        bg = Colors.transparent;
        fg = isEnabled ? AppColors.primary700 : AppColors.textDisabled;
        break;
    }

    double height;
    double fontSize;
    double iconSize;
    EdgeInsets padding;

    switch (size) {
      case AppButtonSize.small:
        height = 34;
        fontSize = 12;
        iconSize = 15;
        padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
        break;
      case AppButtonSize.medium:
        height = 42;
        fontSize = 14;
        iconSize = 18;
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
        break;
      case AppButtonSize.large:
        height = 48;
        fontSize = 15;
        iconSize = 20;
        padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
        break;
    }

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: iconSize, color: fg),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (!isLoading && trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(trailingIcon, size: iconSize, color: fg),
        ],
      ],
    );

    Widget button = Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.roundedSm,
        side: border,
      ),
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: AppRadius.roundedSm,
        child: Container(
          height: height,
          padding: padding,
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
