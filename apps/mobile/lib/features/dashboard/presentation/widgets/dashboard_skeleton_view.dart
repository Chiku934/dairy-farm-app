import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardSkeletonView extends StatelessWidget {
  const DashboardSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter bar skeleton
        Row(
          children: [
            _buildBox(width: 70, height: 32, radius: 16),
            const SizedBox(width: 8),
            _buildBox(width: 90, height: 32, radius: 16),
            const SizedBox(width: 8),
            _buildBox(width: 80, height: 32, radius: 16),
          ],
        ),
        const SizedBox(height: 16),

        // Live status pill skeleton
        _buildBox(height: 38, radius: 8),
        const SizedBox(height: 16),

        // 2x2 Grid KPI cards skeleton
        Row(
          children: [
            Expanded(child: _buildBox(height: 100, radius: 12)),
            const SizedBox(width: 12),
            Expanded(child: _buildBox(height: 100, radius: 12)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildBox(height: 100, radius: 12)),
            const SizedBox(width: 12),
            Expanded(child: _buildBox(height: 100, radius: 12)),
          ],
        ),
        const SizedBox(height: 12),
        _buildBox(height: 48, radius: 10),
        const SizedBox(height: 16),

        // BMC progress skeleton
        _buildBox(height: 90, radius: 12),
        const SizedBox(height: 16),

        // Herd summary skeleton
        _buildBox(height: 90, radius: 12),
        const SizedBox(height: 16),

        // Chart skeleton
        _buildBox(height: 150, radius: 12),
      ],
    );
  }

  Widget _buildBox({
    double? width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
