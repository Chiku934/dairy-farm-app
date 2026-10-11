import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/electricity_models.dart';
import '../electricity_provider.dart';

class RecordElectricityDialog extends ConsumerStatefulWidget {
  const RecordElectricityDialog({super.key});

  @override
  ConsumerState<RecordElectricityDialog> createState() => _RecordElectricityDialogState();
}

class _RecordElectricityDialogState extends ConsumerState<RecordElectricityDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _recordDate;

  ElectricityDepartment _department = ElectricityDepartment.farm;
  final _openingController = TextEditingController(text: '12400.0');
  final _closingController = TextEditingController(text: '12460.0');
  final _tariffController = TextEditingController(text: '1.40');
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _recordDate = DateTime.now();
  }

  @override
  void dispose() {
    _openingController.dispose();
    _closingController.dispose();
    _tariffController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _computedUnits {
    final open = double.tryParse(_openingController.text.trim()) ?? 0.0;
    final close = double.tryParse(_closingController.text.trim()) ?? 0.0;
    return (close - open) > 0 ? (close - open) : 0.0;
  }

  double get _computedCost {
    final tariff = double.tryParse(_tariffController.text.trim()) ?? 1.40;
    return _computedUnits * tariff;
  }

  bool get _isRollbackInvalid {
    final open = double.tryParse(_openingController.text.trim());
    final close = double.tryParse(_closingController.text.trim());
    if (open != null && close != null) {
      return close < open;
    }
    return false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isRollbackInvalid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Closing reading cannot be lower than opening reading (impossible meter rollback).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(electricityRepositoryProvider);
      final open = double.parse(_openingController.text.trim());
      final close = double.parse(_closingController.text.trim());
      final tariff = double.tryParse(_tariffController.text.trim());

      final payload = <String, dynamic>{
        'recordDate': _recordDate.toIso8601String().split('T')[0],
        'department': _department.value,
        'openingReadingKwh': open,
        'closingReadingKwh': close,
        if (tariff != null) 'tariffRate': tariff,
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      };

      await repo.createReading(payload);
      ref.invalidate(electricityReadingsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Electricity meter reading logged successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record electricity reading: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bolt_outlined, color: AppColors.warning),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Log Electricity Meter', style: Theme.of(context).textTheme.titleLarge),
                            Text('Opening & closing counter tracking', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.xl),

                  // Department & Date Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<ElectricityDepartment>(
                          value: _department,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Department Meter *'),
                          items: ElectricityDepartment.values
                              .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _department = val);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _recordDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => _recordDate = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Reading Date',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(_recordDate.toIso8601String().split('T')[0]),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Opening & Closing Meter Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _openingController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Opening Meter (kWh) *',
                            hintText: '12400.0',
                            prefixIcon: Icon(Icons.speed),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final val = double.tryParse(v ?? '');
                            if (val == null || val < 0) return 'Invalid reading';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _closingController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Closing Meter (kWh) *',
                            hintText: '12460.0',
                            prefixIcon: const Icon(Icons.speed),
                            errorText: _isRollbackInvalid ? 'Must be ≥ Opening' : null,
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final val = double.tryParse(v ?? '');
                            if (val == null || val < 0) return 'Invalid reading';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Tariff Rate & Notes
                  TextFormField(
                    controller: _tariffController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Utility Tariff (₹ per kWh unit)',
                      hintText: '1.40',
                      prefixIcon: Icon(Icons.currency_rupee),
                      helperText: 'Defaults to ₹1.40 from Farm Settings if omitted',
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final val = double.tryParse(v);
                      if (val == null || val < 0) return 'Invalid rate';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Sub-meter reading, generator hours, cold room compressor run',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Live Calculated Consumption Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isRollbackInvalid ? AppColors.error : AppColors.neutral200,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Calculated Consumption', style: Theme.of(context).textTheme.bodySmall),
                            Text(
                              '${_computedUnits.toStringAsFixed(1)} kWh',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _isRollbackInvalid ? AppColors.error : AppColors.warning,
                                  ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Estimated Total Cost', style: Theme.of(context).textTheme.bodySmall),
                            Text(
                              '₹${_computedCost.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Submit Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ElevatedButton.icon(
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check),
                        label: Text(_isSubmitting ? 'Saving...' : 'Save Reading'),
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
