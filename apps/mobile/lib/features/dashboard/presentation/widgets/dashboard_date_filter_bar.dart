import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/dashboard_models.dart';
import '../dashboard_provider.dart';

class DashboardDateFilterBar extends ConsumerWidget {
  const DashboardDateFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(dashboardPeriodFilterProvider);
    final customRange = ref.watch(customDateRangeProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildChip(
            context,
            ref,
            filter: DashboardPeriodFilter.today,
            isSelected: currentFilter == DashboardPeriodFilter.today,
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            ref,
            filter: DashboardPeriodFilter.week,
            isSelected: currentFilter == DashboardPeriodFilter.week,
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            ref,
            filter: DashboardPeriodFilter.month,
            isSelected: currentFilter == DashboardPeriodFilter.month,
          ),
          const SizedBox(width: 8),
          _buildCustomChip(
            context,
            ref,
            isSelected: currentFilter == DashboardPeriodFilter.custom,
            customRange: customRange,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    WidgetRef ref, {
    required DashboardPeriodFilter filter,
    required bool isSelected,
  }) {
    return FilterChip(
      selected: isSelected,
      label: Text(
        filter.label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
      selectedColor: AppColors.primary700,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary700 : AppColors.neutralBorder,
        ),
      ),
      onSelected: (_) {
        ref.read(dashboardPeriodFilterProvider.notifier).setFilter(filter);
      },
    );
  }

  Widget _buildCustomChip(
    BuildContext context,
    WidgetRef ref, {
    required bool isSelected,
    required DateTimeRange? customRange,
  }) {
    String label = 'Custom Range';
    if (isSelected && customRange != null) {
      final formatter = DateFormat('MMM d');
      label = '${formatter.format(customRange.start)} - ${formatter.format(customRange.end)}';
    }

    return FilterChip(
      selected: isSelected,
      avatar: Icon(
        Icons.date_range,
        size: 16,
        color: isSelected ? Colors.white : AppColors.primary700,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
      selectedColor: AppColors.primary700,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary700 : AppColors.neutralBorder,
        ),
      ),
      onSelected: (_) async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: customRange ??
              DateTimeRange(
                start: DateTime.now().subtract(const Duration(days: 7)),
                end: DateTime.now(),
              ),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary700,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          ref.read(customDateRangeProvider.notifier).setRange(picked);
          ref.read(dashboardPeriodFilterProvider.notifier).setFilter(
                DashboardPeriodFilter.custom,
              );
        }
      },
    );
  }
}
