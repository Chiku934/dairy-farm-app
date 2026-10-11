import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/herd_models.dart';

class HerdFilterBar extends StatelessWidget {
  final AnimalStatus? selectedStatus;
  final bool includeArchived;
  final HerdSummaryCountsModel summary;
  final ValueChanged<AnimalStatus?> onStatusChanged;
  final ValueChanged<bool> onIncludeArchivedChanged;

  const HerdFilterBar({
    super.key,
    required this.selectedStatus,
    required this.includeArchived,
    required this.summary,
    required this.onStatusChanged,
    required this.onIncludeArchivedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildChip(
                label: 'All Active (${summary.totalActive})',
                isSelected: selectedStatus == null && !includeArchived,
                onTap: () {
                  onIncludeArchivedChanged(false);
                  onStatusChanged(null);
                },
              ),
              const SizedBox(width: 8),
              _buildChip(
                label: 'Lactating (${summary.lactating})',
                isSelected: selectedStatus == AnimalStatus.lactating,
                onTap: () => onStatusChanged(AnimalStatus.lactating),
              ),
              const SizedBox(width: 8),
              _buildChip(
                label: 'Dry (${summary.dry})',
                isSelected: selectedStatus == AnimalStatus.dry,
                onTap: () => onStatusChanged(AnimalStatus.dry),
              ),
              const SizedBox(width: 8),
              _buildChip(
                label: 'Pregnant (${summary.pregnant})',
                isSelected: selectedStatus == AnimalStatus.pregnant,
                onTap: () => onStatusChanged(AnimalStatus.pregnant),
              ),
              const SizedBox(width: 8),
              _buildChip(
                label: 'Heifers (${summary.heifer})',
                isSelected: selectedStatus == AnimalStatus.heifer,
                onTap: () => onStatusChanged(AnimalStatus.heifer),
              ),
              const SizedBox(width: 8),
              _buildChip(
                label: 'Calves (${summary.calf})',
                isSelected: selectedStatus == AnimalStatus.calf,
                onTap: () => onStatusChanged(AnimalStatus.calf),
              ),
              const SizedBox(width: 8),
              _buildChip(
                label: 'Bulls (${summary.bull})',
                isSelected: selectedStatus == AnimalStatus.bull,
                onTap: () => onStatusChanged(AnimalStatus.bull),
              ),
              const SizedBox(width: 8),
              _buildChip(
                label: 'Archived (${summary.archived})',
                isSelected: includeArchived,
                onTap: () {
                  onIncludeArchivedChanged(!includeArchived);
                  if (!includeArchived) onStatusChanged(null);
                },
                isArchiveVariant: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isArchiveVariant = false,
  }) {
    Color selectedBg = isArchiveVariant ? Colors.grey.shade200 : AppColors.primary100;
    Color selectedBorder = isArchiveVariant ? Colors.grey.shade400 : AppColors.primary500;
    Color selectedTextColor = isArchiveVariant ? Colors.grey.shade800 : AppColors.primary800;

    return Material(
      color: isSelected ? selectedBg : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? selectedBorder : AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? selectedTextColor : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
