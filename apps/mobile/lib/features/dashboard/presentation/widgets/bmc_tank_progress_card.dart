import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/dashboard_models.dart';

class BmcTankProgressCard extends StatelessWidget {
  final BmcStatusModel bmc;

  const BmcTankProgressCard({super.key, required this.bmc});

  @override
  Widget build(BuildContext context) {
    Color barColor;
    Color statusBg;
    Color statusTextColor;
    String statusLabel;

    if (bmc.utilizationPercent >= 90) {
      barColor = AppColors.statusError;
      statusBg = const Color(0xFFFEE2E2);
      statusTextColor = AppColors.statusError;
      statusLabel = 'Near Full (Critical)';
    } else if (bmc.utilizationPercent >= 75) {
      barColor = AppColors.statusWarning;
      statusBg = AppColors.warningBg;
      statusTextColor = AppColors.statusWarning;
      statusLabel = 'High Capacity';
    } else {
      barColor = AppColors.primary700;
      statusBg = AppColors.primary50;
      statusTextColor = AppColors.primary800;
      statusLabel = 'Normal Operating';
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primary700),
                  SizedBox(width: 8),
                  Text(
                    'Bulk Milk Cooler (BMC)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Tank Balance: ${bmc.currentBalanceLitres} L',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${bmc.utilizationPercent}% (${bmc.capacityLitres.toInt()} L cap)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (bmc.utilizationPercent / 100.0).clamp(0.0, 1.0),
              backgroundColor: AppColors.neutral100,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
