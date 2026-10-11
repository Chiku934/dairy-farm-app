import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/dashboard_models.dart';

class DashboardKpiCards extends StatelessWidget {
  final DashboardOverviewModel data;

  const DashboardKpiCards({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 2x2 Grid for Mobile (or Row on Tablet)
        LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            if (isTablet) {
              return Row(
                children: [
                  Expanded(child: _buildMilkCard()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSalesCard()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildOperatingCostCard()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildFertiliserCard()),
                ],
              );
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildMilkCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSalesCard()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildOperatingCostCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildFertiliserCard()),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),

        // Cost per Litre Banner
        _buildCostPerLitreBanner(),
      ],
    );
  }

  Widget _buildMilkCard() {
    final m = data.milkRecorded;
    final amPmStr = (m.amYield != null && m.pmYield != null)
        ? 'AM: ${m.amYield} L · PM: ${m.pmYield} L'
        : 'Daily eligible milk';

    return _KpiContainer(
      title: 'Milk Recorded',
      value: '${m.value} ${m.unit ?? "L"}',
      subtitle: amPmStr,
      icon: Icons.water_drop,
      iconColor: AppColors.primary700,
      deltaPercent: m.deltaPercent,
    );
  }

  Widget _buildSalesCard() {
    final s = data.salesRevenue;
    if (s == null) {
      return const _RestrictedKpiContainer(
        title: 'Sales Revenue',
        icon: Icons.currency_rupee,
      );
    }

    return _KpiContainer(
      title: 'Sales Revenue',
      value: '₹${s.value.toStringAsFixed(s.value.truncateToDouble() == s.value ? 0 : 2)}',
      subtitle: 'Dispatches recorded',
      icon: Icons.currency_rupee,
      iconColor: AppColors.statusSuccess,
      deltaPercent: s.deltaPercent,
    );
  }

  Widget _buildOperatingCostCard() {
    final c = data.operatingCost;
    if (c == null) {
      return const _RestrictedKpiContainer(
        title: 'Operating Cost',
        icon: Icons.receipt_long,
      );
    }

    return _KpiContainer(
      title: 'Operating Cost',
      value: '₹${c.value.toStringAsFixed(2)}',
      subtitle: 'Feed, Meds, Power, Wages',
      icon: Icons.receipt_long,
      iconColor: AppColors.accentTeal,
      deltaPercent: c.deltaPercent,
    );
  }

  Widget _buildFertiliserCard() {
    final f = data.dryFertiliser;
    return _KpiContainer(
      title: 'Dry Fertiliser',
      value: '${f.value} ${f.unit ?? "kg"}',
      subtitle: 'Biogas solar dried',
      icon: Icons.eco,
      iconColor: AppColors.accentEmerald,
      deltaPercent: f.deltaPercent,
    );
  }

  Widget _buildCostPerLitreBanner() {
    final cpl = data.costPerLitre;

    String displayValue;
    Color badgeColor;
    Color textColor;
    String statusLabel;

    if (cpl.status == 'CALCULATED' && cpl.value != null) {
      displayValue = '₹${cpl.value!.toStringAsFixed(2)} / Litre';
      badgeColor = AppColors.primary50;
      textColor = AppColors.primary800;
      statusLabel = 'Calculated';
    } else if (cpl.status == 'RESTRICTED') {
      displayValue = 'Access Restricted';
      badgeColor = AppColors.neutral100;
      textColor = AppColors.neutral700;
      statusLabel = 'Restricted';
    } else {
      displayValue = 'Incomplete';
      badgeColor = AppColors.warningBg;
      textColor = AppColors.statusWarning;
      statusLabel = 'Pending Milk Log';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_outlined, size: 18, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Unit Milk Cost: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.85),
                      ),
                    ),
                    Text(
                      displayValue,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                if (cpl.formulaExplanation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      cpl.formulaExplanation,
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: textColor.withOpacity(0.3)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiContainer extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final double? deltaPercent;

  const _KpiContainer({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.deltaPercent,
  });

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (deltaPercent != null) ...[
                const SizedBox(width: 4),
                _buildDeltaBadge(deltaPercent!),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaBadge(double delta) {
    final isPositive = delta >= 0;
    final color = isPositive ? AppColors.statusSuccess : AppColors.statusError;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          Text(
            '${delta.abs()}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestrictedKpiContainer extends StatelessWidget {
  final String title;
  final IconData icon;

  const _RestrictedKpiContainer({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutralBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Restricted',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Finance authorization required',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
