import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class AppKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final double? trendPercent;
  final String? trendLabel;
  final bool isExecutive;
  final VoidCallback? onTap;

  const AppKpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.trendPercent,
    this.trendLabel,
    this.isExecutive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isExecutive ? AppColors.primary900 : AppColors.cardSurface;
    final titleColor = isExecutive ? const Color(0xAAFFFFFF) : AppColors.textMuted;
    final valueColor = isExecutive ? Colors.white : AppColors.textMain;
    final subColor = isExecutive ? const Color(0xCCFFFFFF) : AppColors.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(
          color: isExecutive ? AppColors.primary800 : AppColors.borderSubtle,
          width: 1,
        ),
        boxShadow: isExecutive ? [] : AppElevation.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.roundedMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: AppTypography.sectionHeader(color: titleColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isExecutive
                              ? const Color(0x22FFFFFF)
                              : AppColors.primary50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          icon,
                          size: 15,
                          color: isExecutive ? Colors.white : AppColors.primary700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: valueColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (trendPercent != null) ...[
                      _buildTrendBadge(),
                      const SizedBox(width: 4),
                    ],
                    if (subtitle != null) ...[
                      Expanded(
                        child: Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: subColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendBadge() {
    final isPositive = trendPercent! >= 0;
    final color = isPositive ? AppColors.statusSuccess : AppColors.statusDanger;
    final bg = isPositive
        ? AppColors.statusSuccessSurface
        : AppColors.statusDangerSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${isPositive ? '+' : ''}${trendPercent!.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
