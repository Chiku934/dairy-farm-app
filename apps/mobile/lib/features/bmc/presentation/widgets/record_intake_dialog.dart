import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/bmc_models.dart';
import '../bmc_provider.dart';

class RecordIntakeDialog extends ConsumerStatefulWidget {
  const RecordIntakeDialog({super.key});

  @override
  ConsumerState<RecordIntakeDialog> createState() => _RecordIntakeDialogState();
}

class _RecordIntakeDialogState extends ConsumerState<RecordIntakeDialog> {
  final _formKey = GlobalKey<FormState>();

  MilkIntakeSource _source = MilkIntakeSource.farm;
  IntakeShift _shift = IntakeShift.am;
  IntakeDecision _decision = IntakeDecision.accepted;
  late DateTime _selectedDate;

  final _quantityController = TextEditingController();
  final _routeController = TextEditingController();
  final _costController = TextEditingController();
  final _tempController = TextEditingController();
  final _fatController = TextEditingController();
  final _snfController = TextEditingController();
  final _clrController = TextEditingController();
  final _phController = TextEditingController();
  final _rejectionReasonController = TextEditingController();
  final _operatorController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _routeController.dispose();
    _costController.dispose();
    _tempController.dispose();
    _fatController.dispose();
    _snfController.dispose();
    _clrController.dispose();
    _phController.dispose();
    _rejectionReasonController.dispose();
    _operatorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = double.tryParse(_quantityController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity in litres.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = <String, dynamic>{
        'recordDate': _selectedDate.toIso8601String().split('T')[0],
        'shift': _shift.value,
        'source': _source.value,
        'quantityLitres': qty,
        'decision': _decision.value,
      };

      if (_source == MilkIntakeSource.external) {
        if (_routeController.text.trim().isNotEmpty) {
          payload['supplierRoute'] = _routeController.text.trim();
        }
        final cost = double.tryParse(_costController.text.trim());
        if (cost != null) payload['externalTotalCost'] = cost;
      }

      if (_decision == IntakeDecision.rejected) {
        payload['rejectionReason'] = _rejectionReasonController.text.trim();
      }

      if (_tempController.text.trim().isNotEmpty) {
        payload['temperatureC'] = double.tryParse(_tempController.text.trim());
      }
      if (_fatController.text.trim().isNotEmpty) {
        payload['fatPercentage'] = double.tryParse(_fatController.text.trim());
      }
      if (_snfController.text.trim().isNotEmpty) {
        payload['snfPercentage'] = double.tryParse(_snfController.text.trim());
      }
      if (_clrController.text.trim().isNotEmpty) {
        payload['clr'] = double.tryParse(_clrController.text.trim());
      }
      if (_phController.text.trim().isNotEmpty) {
        payload['ph'] = double.tryParse(_phController.text.trim());
      }
      if (_operatorController.text.trim().isNotEmpty) {
        payload['operatorName'] = _operatorController.text.trim();
      }
      if (_notesController.text.trim().isNotEmpty) {
        payload['notes'] = _notesController.text.trim();
      }

      final repo = ref.read(bmcRepositoryProvider);
      await repo.createIntake(payload);

      ref.invalidate(bmcIntakeListProvider);
      ref.invalidate(bmcTankBalanceProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _decision == IntakeDecision.accepted
                  ? 'Intake recorded successfully. BMC balance updated.'
                  : 'Rejected intake recorded and segregated.',
            ),
            backgroundColor: _decision == IntakeDecision.accepted ? AppColors.success : AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording intake: $e'),
            backgroundColor: AppColors.danger,
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
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 720),
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
                    Text('Record Milk Intake', style: AppTypography.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Source Toggle (Farm vs External)
                SegmentedButton<MilkIntakeSource>(
                  segments: const [
                    ButtonSegment(
                      value: MilkIntakeSource.farm,
                      label: Text('Internal Farm'),
                      icon: Icon(Icons.agriculture_outlined),
                    ),
                    ButtonSegment(
                      value: MilkIntakeSource.external,
                      label: Text('External Supplier'),
                      icon: Icon(Icons.local_shipping_outlined),
                    ),
                  ],
                  selected: {_source},
                  onSelectionChanged: (set) => setState(() => _source = set.first),
                ),
                const SizedBox(height: AppSpacing.md),

                // Date and Shift Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Intake Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(_selectedDate.toIso8601String().split('T')[0]),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DropdownButtonFormField<IntakeShift>(
                        value: _shift,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Shift',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        items: IntakeShift.values
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.value)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _shift = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                if (_source == MilkIntakeSource.external) ...[
                  TextFormField(
                    controller: _routeController,
                    decoration: const InputDecoration(
                      labelText: 'Supplier Route / Village',
                      hintText: 'e.g. Dandiri Route 1, Farmer Group B',
                      prefixIcon: Icon(Icons.route_outlined),
                    ),
                    validator: (v) => _source == MilkIntakeSource.external && (v == null || v.trim().isEmpty)
                        ? 'Supplier route is required'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _costController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Total Cost (₹)',
                      hintText: 'e.g. 5250.00',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // Quantity (L)
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Intake Quantity (Litres) *',
                    hintText: 'e.g. 150.00',
                    prefixIcon: Icon(Icons.water_drop_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Quantity is required';
                    final numVal = double.tryParse(v.trim());
                    if (numVal == null || numVal <= 0) return 'Enter a valid positive quantity';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // QC Testing Section Card
                Card(
                  color: AppColors.background,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quality Control (QC) Inspection', style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Standard: Fat ≥ 3.2%, SNF ≥ 8.0%, Temp ≤ 10°C, pH 6.5-6.8',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _tempController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Temp (°C)', hintText: '4.2'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextFormField(
                                controller: _fatController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Fat (%)', hintText: '4.20'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextFormField(
                                controller: _snfController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'SNF (%)', hintText: '8.65'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _clrController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'CLR', hintText: '29.0'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextFormField(
                                controller: _phController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'pH', hintText: '6.68'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Decision (Accepted vs Rejected)
                DropdownButtonFormField<IntakeDecision>(
                  value: _decision,
                  decoration: const InputDecoration(
                    labelText: 'Intake Decision *',
                    prefixIcon: Icon(Icons.verified_outlined),
                  ),
                  items: IntakeDecision.values
                      .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _decision = val);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                if (_decision == IntakeDecision.rejected) ...[
                  TextFormField(
                    controller: _rejectionReasonController,
                    decoration: const InputDecoration(
                      labelText: 'Rejection Reason *',
                      hintText: 'e.g. Souring, temperature > 12°C, adulteration',
                      prefixIcon: Icon(Icons.warning_amber_rounded),
                    ),
                    validator: (v) => _decision == IntakeDecision.rejected && (v == null || v.trim().isEmpty)
                        ? 'Rejection reason is required'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // Operator & Notes
                TextFormField(
                  controller: _operatorController,
                  decoration: const InputDecoration(
                    labelText: 'Authorized Operator / Tester',
                    hintText: 'Operator name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Inspection Notes',
                    hintText: 'Optional batch comments',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
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
                      label: const Text('Save Intake'),
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
