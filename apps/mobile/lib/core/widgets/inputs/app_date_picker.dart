import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class AppDatePickerField extends StatelessWidget {
  final String? label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? hint;
  final String? errorText;
  final bool isRequired;
  final bool enabled;

  const AppDatePickerField({
    super.key,
    this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.hint = 'Select date',
    this.errorText,
    this.isRequired = false,
    this.enabled = true,
  });

  Future<void> _pickDate(BuildContext context) async {
    if (!enabled) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary700,
              onPrimary: Colors.white,
              surface: AppColors.cardSurface,
              onSurface: AppColors.textMain,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = selectedDate != null
        ? DateFormat('dd MMM yyyy').format(selectedDate!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text.rich(
            TextSpan(
              text: label!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              children: [
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.statusDanger,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        InkWell(
          onTap: enabled ? () => _pickDate(context) : null,
          borderRadius: AppRadius.roundedSm,
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorText,
              prefixIcon: const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
              suffixIcon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.textMuted,
              ),
            ),
            child: Text(
              displayText ?? hint ?? '',
              style: TextStyle(
                fontSize: 14,
                color: displayText != null
                    ? AppColors.textMain
                    : AppColors.textDisabled,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
