import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/quality_models.dart';
import '../quality_provider.dart';

class RecordQualityDialog extends ConsumerStatefulWidget {
  final QualityTargetType? initialTargetType;
  final String? initialTargetId;

  const RecordQualityDialog({
    super.key,
    this.initialTargetType,
    this.initialTargetId,
  });

  @override
  ConsumerState<RecordQualityDialog> createState() => _RecordQualityDialogState();
}

class _RecordQualityDialogState extends ConsumerState<RecordQualityDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _recordDate;

  late QualityTargetType _targetType;
  late final TextEditingController _targetIdController;
  final _fatController = TextEditingController(text: '4.2');
  final _snfController = TextEditingController(text: '8.8');
  final _clrController = TextEditingController(text: '30.0');
  final _phController = TextEditingController(text: '6.68');
  final _tempController = TextEditingController(text: '4.0');
  final _testedByController = TextEditingController();
  final _notesController = TextEditingController();

  QualityDecision _decision = QualityDecision.approved;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _recordDate = DateTime.now();
    _targetType = widget.initialTargetType ?? QualityTargetType.productionBatch;
    _targetIdController = TextEditingController(text: widget.initialTargetId ?? '');
  }

  @override
  void dispose() {
    _targetIdController.dispose();
    _fatController.dispose();
    _snfController.dispose();
    _clrController.dispose();
    _phController.dispose();
    _tempController.dispose();
    _testedByController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(qualityRepositoryProvider);

      final payload = <String, dynamic>{
        'recordDate': _recordDate.toIso8601String().split('T')[0],
        'targetType': _targetType.value,
        'targetId': _targetIdController.text.trim(),
        'decision': _decision.value,
      };

      final fat = double.tryParse(_fatController.text.trim());
      if (fat != null) payload['fatPercentage'] = fat;

      final snf = double.tryParse(_snfController.text.trim());
      if (snf != null) payload['snfPercentage'] = snf;

      final clr = double.tryParse(_clrController.text.trim());
      if (clr != null) payload['clr'] = clr;

      final ph = double.tryParse(_phController.text.trim());
      if (ph != null) payload['ph'] = ph;

      final temp = double.tryParse(_tempController.text.trim());
      if (temp != null) payload['temperatureC'] = temp;

      if (_testedByController.text.trim().isNotEmpty) {
        payload['testedBy'] = _testedByController.text.trim();
      }
      if (_notesController.text.trim().isNotEmpty) {
        payload['notes'] = _notesController.text.trim();
      }

      await repo.createRecord(payload);
      ref.invalidate(qualityRecordsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quality record saved successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save quality record: $e'),
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
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
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
                          color: AppColors.secondary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_outlined, color: AppColors.secondary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Record Quality Test', style: Theme.of(context).textTheme.titleLarge),
                            Text('Lab parameters & release decision', style: Theme.of(context).textTheme.bodySmall),
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

                  // Target Type & Target ID
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<QualityTargetType>(
                          value: _targetType,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Target Type'),
                          items: QualityTargetType.values
                              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _targetType = val);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _targetIdController,
                          decoration: const InputDecoration(
                            labelText: 'Target ID / Batch ID *',
                            hintText: 'UUID or batch reference',
                            prefixIcon: Icon(Icons.tag),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Date & Decision Row
                  Row(
                    children: [
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
                              labelText: 'Test Date',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(_recordDate.toIso8601String().split('T')[0]),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: DropdownButtonFormField<QualityDecision>(
                          value: _decision,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Decision *'),
                          items: QualityDecision.values
                              .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _decision = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Fat % & SNF %
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _fatController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Fat %',
                            hintText: '4.2',
                            prefixIcon: Icon(Icons.water_drop_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            final val = double.tryParse(v);
                            if (val == null || val < 0 || val > 100) return '0 - 100%';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _snfController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'SNF %',
                            hintText: '8.8',
                            prefixIcon: Icon(Icons.opacity),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            final val = double.tryParse(v);
                            if (val == null || val < 0 || val > 100) return '0 - 100%';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // CLR, pH, Temp Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _clrController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'CLR (10-45)', hintText: '30.0'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            final val = double.tryParse(v);
                            if (val == null || val < 10 || val > 45) return '10 - 45';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: TextFormField(
                          controller: _phController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'pH (0-14)', hintText: '6.68'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            final val = double.tryParse(v);
                            if (val == null || val < 0 || val > 14) return '0 - 14';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: TextFormField(
                          controller: _tempController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Temp (°C)', hintText: '4.0'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            final val = double.tryParse(v);
                            if (val == null || val < -10 || val > 100) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Tested By & Notes
                  TextFormField(
                    controller: _testedByController,
                    decoration: const InputDecoration(
                      labelText: 'Tested By (Operator / QC Officer)',
                      hintText: 'e.g. Ramesh Patel, Lab Tech',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Sensory / Organoleptic Notes (Optional)',
                      hintText: 'Fresh smell, clean white appearance, standard acidity',
                      prefixIcon: Icon(Icons.notes),
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
                        label: Text(_isSubmitting ? 'Saving...' : 'Save Record'),
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
