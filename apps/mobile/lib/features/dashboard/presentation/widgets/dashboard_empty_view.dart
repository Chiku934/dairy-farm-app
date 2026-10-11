import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardEmptyView extends StatelessWidget {
  final VoidCallback onResetPeriod;

  const DashboardEmptyView({super.key, required this.onResetPeriod});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutralBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_busy, size: 28, color: AppColors.primary700),
          ),
          const SizedBox(height: 12),
          const Text(
            'No Farm Records for Period',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'There are no milk logs, sales, or expenses recorded in the selected period.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onResetPeriod,
            icon: const Icon(Icons.today, size: 16),
            label: const Text('View Today\'s Records'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary700,
              side: const BorderSide(color: AppColors.primary700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
