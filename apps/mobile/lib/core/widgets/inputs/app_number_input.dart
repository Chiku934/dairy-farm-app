import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class AppNumberInputField extends StatefulWidget {
  final String? label;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final double step;
  final int decimalPlaces;
  final String? unitSuffix;
  final bool isRequired;
  final bool enabled;

  const AppNumberInputField({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 100000.0,
    this.step = 1.0,
    this.decimalPlaces = 1,
    this.unitSuffix,
    this.isRequired = false,
    this.enabled = true,
  });

  @override
  State<AppNumberInputField> createState() => _AppNumberInputFieldState();
}

class _AppNumberInputFieldState extends State<AppNumberInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
  }

  @override
  void didUpdateWidget(AppNumberInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final currentParsed = double.tryParse(_controller.text) ?? 0.0;
      if ((currentParsed - widget.value).abs() > 0.001) {
        _controller.text = _formatValue(widget.value);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatValue(double val) {
    return widget.decimalPlaces == 0
        ? val.toInt().toString()
        : val.toStringAsFixed(widget.decimalPlaces);
  }

  void _stepDown() {
    if (!widget.enabled) return;
    final next = (widget.value - widget.step).clamp(widget.min, widget.max);
    widget.onChanged(next);
    _controller.text = _formatValue(next);
  }

  void _stepUp() {
    if (!widget.enabled) return;
    final next = (widget.value + widget.step).clamp(widget.min, widget.max);
    widget.onChanged(next);
    _controller.text = _formatValue(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text.rich(
            TextSpan(
              text: widget.label!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              children: [
                if (widget.isRequired)
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
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: AppRadius.roundedSm,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                color: widget.value <= widget.min
                    ? AppColors.textDisabled
                    : AppColors.primary800,
                onPressed:
                    widget.enabled && widget.value > widget.min ? _stepDown : null,
                splashRadius: 20,
              ),
              const VerticalDivider(width: 1, color: AppColors.borderSubtle),
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: widget.enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (text) {
                    final parsed = double.tryParse(text);
                    if (parsed != null) {
                      final clamped = parsed.clamp(widget.min, widget.max);
                      widget.onChanged(clamped);
                      _controller.text = _formatValue(clamped);
                    } else {
                      _controller.text = _formatValue(widget.value);
                    }
                  },
                ),
              ),
              if (widget.unitSuffix != null) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    widget.unitSuffix!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
              const VerticalDivider(width: 1, color: AppColors.borderSubtle),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                color: widget.value >= widget.max
                    ? AppColors.textDisabled
                    : AppColors.primary800,
                onPressed:
                    widget.enabled && widget.value < widget.max ? _stepUp : null,
                splashRadius: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
