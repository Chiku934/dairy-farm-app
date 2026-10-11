import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/dashboard_models.dart';

class RecentActivitySection extends StatelessWidget {
  final List<RecentActivityModel> activities;

  const RecentActivitySection({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutralBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, size: 18, color: AppColors.primary700),
              SizedBox(width: 8),
              Text(
                'Recent Operational Activity',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (_, __) => const Divider(
              color: AppColors.neutral100,
              height: 16,
            ),
            itemBuilder: (context, index) {
              final act = activities[index];
              return _buildActivityRow(act);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(RecentActivityModel act) {
    IconData icon;
    Color iconColor;

    switch (act.category) {
      case 'MILKING':
        icon = Icons.water_drop_outlined;
        iconColor = AppColors.primary700;
        break;
      case 'BMC':
        icon = Icons.local_drink_outlined;
        iconColor = AppColors.accentTeal;
        break;
      case 'SALES':
        icon = Icons.local_shipping_outlined;
        iconColor = AppColors.statusSuccess;
        break;
      case 'HEALTH':
        icon = Icons.medical_services_outlined;
        iconColor = AppColors.statusError;
        break;
      case 'QUALITY':
        icon = Icons.verified_outlined;
        iconColor = AppColors.accentEmerald;
        break;
      case 'AUDIT':
      default:
        icon = Icons.security_outlined;
        iconColor = AppColors.neutral600;
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                act.title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                act.description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (act.badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              act.badge!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
      ],
    );
  }
}
