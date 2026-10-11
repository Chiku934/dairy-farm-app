import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/dashboard_models.dart';

class DashboardAlertsSection extends StatelessWidget {
  final List<DashboardAlertModel> alerts;

  const DashboardAlertsSection({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, size: 18, color: AppColors.statusSuccess),
            SizedBox(width: 8),
            Text(
              'No active alerts. Operational systems running smoothly.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary800,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.statusWarning),
                SizedBox(width: 8),
                Text(
                  'Attention & Action Required',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${alerts.length} Active',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.statusError,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: alerts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return _buildAlertTile(alert);
          },
        ),
      ],
    );
  }

  Widget _buildAlertTile(DashboardAlertModel alert) {
    Color bg;
    Color border;
    Color iconColor;
    IconData icon;

    switch (alert.severity) {
      case 'CRITICAL':
        bg = const Color(0xFFFFF1F2);
        border = const Color(0xFFFECDD3);
        iconColor = AppColors.statusError;
        icon = Icons.error_outline;
        break;
      case 'WARNING':
        bg = AppColors.warningBg;
        border = const Color(0xFFFED7AA);
        iconColor = AppColors.statusWarning;
        icon = Icons.warning_amber_outlined;
        break;
      case 'INFO':
      default:
        bg = AppColors.primary50;
        border = const Color(0xFFBBF7D0);
        iconColor = AppColors.primary700;
        icon = Icons.info_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.description,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (alert.daysRemaining != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: border),
              ),
              child: Text(
                '${alert.daysRemaining}d left',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
