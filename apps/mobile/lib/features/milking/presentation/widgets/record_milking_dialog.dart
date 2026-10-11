import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../milking_provider.dart';
import '../../domain/milking_models.dart';

class RecordMilkingDialog extends ConsumerStatefulWidget {
  const RecordMilkingDialog({super.key});

  @override
  ConsumerState<RecordMilkingDialog> createState() => _RecordMilkingDialogState();
}

class _RecordMilkingDialogState extends ConsumerState<RecordMilkingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _earTagController = TextEditingController();
  final _groupController = TextEditingController();
  final _yieldController = TextEditingController();
  final _withheldReasonController = TextEditingController();
  final _operatorController = TextEditingController(text: 'Current Operator');
  final _notesController = TextEditingController();

  bool _isGroup = false;
  String _selectedDate = DateTime.now().toIso8601String().split('T')[0];
  MilkingSession _session = MilkingSession.morning;
  MilkDisposition _disposition = MilkDisposition.eligible;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _earTagController.dispose();
    _groupController.dispose();
    _yieldController.dispose();
    _withheldReasonController.dispose();
    _operatorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final yieldVal = double.tryParse(_yieldController.text.trim());
    if (yieldVal == null || yieldVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid milk yield quantity greater than 0.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(milkingRepositoryProvider);
      await repo.createMilkingLog(
        animalId: _isGroup ? null : _earTagController.text.trim(),
        groupName: _isGroup ? _groupController.text.trim() : null,
        recordDate: _selectedDate,
        session: _session,
        yieldLitres: yieldVal,
        disposition: _disposition,
        withheldReason: _disposition == MilkDisposition.withheld ? _withheldReasonController.text.trim() : null,
        operatorName: _operatorController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (mounted) {
        ref.invalidate(milkingLogsProvider);
        ref.invalidate(milkingSummaryProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Milking session recorded successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Record Milking Session', style: AppTypography.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Group vs Individual Switch
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Individual Cow'), icon: Icon(Icons.pets)),
                    ButtonSegment(value: true, label: Text('Group / Herd'), icon: Icon(Icons.groups)),
                  ],
                  selected: {_isGroup},
                  onSelectionChanged: (val) => setState(() => _isGroup = val.first),
                ),
                const SizedBox(height: AppSpacing.md),

                if (!_isGroup) ...[
                  TextFormField(
                    controller: _earTagController,
                    decoration: const InputDecoration(
                      labelText: 'Cow Tag / ID *',
                      hintText: 'e.g. c-01 or 210385',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Ear Tag is required' : null,
                  ),
                ] else ...[
                  TextFormField(
                    controller: _groupController,
                    decoration: const InputDecoration(
                      labelText: 'Group Name *',
                      hintText: 'e.g. Group 1 - High Yielders',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Group name is required' : null,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),

                // Date & Shift
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.parse(_selectedDate),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked.toIso8601String().split('T')[0]);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(_selectedDate, style: AppTypography.bodyMedium),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DropdownButtonFormField<MilkingSession>(
                        value: _session,
                        decoration: const InputDecoration(
                          labelText: 'Shift / Session',
                          prefixIcon: Icon(Icons.wb_sunny_outlined),
                        ),
                        items: MilkingSession.values
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _session = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Yield in Litres
                TextFormField(
                  controller: _yieldController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Yield (Litres) *',
                    hintText: '14.50',
                    prefixIcon: Icon(Icons.water_drop_outlined),
                    suffixText: 'L',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Yield is required';
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Disposition Selection
                DropdownButtonFormField<MilkDisposition>(
                  value: _disposition,
                  decoration: const InputDecoration(
                    labelText: 'Milk Disposition',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  items: MilkDisposition.values
                      .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _disposition = val);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                if (_disposition == MilkDisposition.withheld) ...[
                  TextFormField(
                    controller: _withheldReasonController,
                    decoration: const InputDecoration(
                      labelText: 'Withheld Reason *',
                      hintText: 'e.g. Active antibiotic treatment, high somatic cell',
                      prefixIcon: Icon(Icons.warning_amber_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please specify reason for withholding' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Operator
                TextFormField(
                  controller: _operatorController,
                  decoration: const InputDecoration(
                    labelText: 'Operator / Milker',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Observations during milking',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check),
                      label: const Text('Save Record'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
