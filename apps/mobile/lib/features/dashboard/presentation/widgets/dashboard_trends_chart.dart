import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/dashboard_models.dart';

class DashboardTrendsChart extends StatelessWidget {
  final List<DailyYieldTrendModel> dailyYields;
  final List<DailyRevenueTrendModel>? dailyRevenue;

  const DashboardTrendsChart({
    super.key,
    required this.dailyYields,
    this.dailyRevenue,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyYields.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxYield = dailyYields.fold<double>(
      0.0,
      (prev, el) => el.totalYield > prev ? el.totalYield : prev,
    );

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
                  Icon(Icons.bar_chart, size: 18, color: AppColors.primary700),
                  SizedBox(width: 8),
                  Text(
                    'Daily Yield Trends',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegend(color: AppColors.primary700, label: 'Morning'),
                  const SizedBox(width: 10),
                  _buildLegend(color: AppColors.accentTeal, label: 'Evening'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Yield Bar Chart
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyYields.map((trend) {
                final normalizedMax = maxYield > 0 ? maxYield : 1.0;
                final morningHeight = (trend.morningYield / normalizedMax) * 90;
                final eveningHeight = (trend.eveningYield / normalizedMax) * 90;

                final dayLabel = trend.date.length >= 10
                    ? trend.date.substring(8, 10)
                    : trend.date;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${trend.totalYield.toInt()}L',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 10,
                            height: morningHeight.clamp(4.0, 90.0),
                            decoration: BoxDecoration(
                              color: AppColors.primary700,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Container(
                            width: 10,
                            height: eveningHeight.clamp(4.0, 90.0),
                            decoration: BoxDecoration(
                              color: AppColors.accentTeal,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dayLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
