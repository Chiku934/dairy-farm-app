import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

enum AppStatusType {
  success,
  warning,
  danger,
  info,
  neutral,
}

class AppStatusChip extends StatelessWidget {
  final String label;
  final AppStatusType type;
  final bool showDot;
  final IconData? icon;

  const AppStatusChip({
    super.key,
    required this.label,
    this.type = AppStatusType.neutral,
    this.showDot = true,
    this.icon,
  });

  const AppStatusChip.success({
    super.key,
    required this.label,
    this.showDot = true,
    this.icon,
  }) : type = AppStatusType.success;

  const AppStatusChip.warning({
    super.key,
    required this.label,
    this.showDot = true,
    this.icon,
  }) : type = AppStatusType.warning;

  const AppStatusChip.danger({
    super.key,
    required this.label,
    this.showDot = true,
    this.icon,
  }) : type = AppStatusType.danger;

  const AppStatusChip.info({
    super.key,
    required this.label,
    this.showDot = true,
    this.icon,
  }) : type = AppStatusType.info;

  const AppStatusChip.neutral({
    super.key,
    required this.label,
    this.showDot = false,
    this.icon,
  }) : type = AppStatusType.neutral;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (type) {
      case AppStatusType.success:
        bg = AppColors.statusSuccessSurface;
        fg = AppColors.statusSuccess;
        border = AppColors.statusSuccessBorder;
        break;
      case AppStatusType.warning:
        bg = AppColors.statusWarningSurface;
        fg = AppColors.statusWarning;
        border = AppColors.statusWarningBorder;
        break;
      case AppStatusType.danger:
        bg = AppColors.statusDangerSurface;
        fg = AppColors.statusDanger;
        border = AppColors.statusDangerBorder;
        break;
      case AppStatusType.info:
        bg = AppColors.statusInfoSurface;
        fg = AppColors.statusInfo;
        border = AppColors.statusInfoBorder;
        break;
      case AppStatusType.neutral:
        bg = AppColors.statusNeutralSurface;
        fg = AppColors.statusNeutral;
        border = AppColors.statusNeutralBorder;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.roundedFull,
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
