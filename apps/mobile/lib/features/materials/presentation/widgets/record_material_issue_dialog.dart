import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/material_models.dart';
import '../material_provider.dart';

class RecordMaterialIssueDialog extends ConsumerStatefulWidget {
  const RecordMaterialIssueDialog({super.key});

  @override
  ConsumerState<RecordMaterialIssueDialog> createState() => _RecordMaterialIssueDialogState();
}

class _RecordMaterialIssueDialogState extends ConsumerState<RecordMaterialIssueDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _recordDate;

  IssueDepartment _department = IssueDepartment.production;
  final _stockItemIdController = TextEditingController(text: 'item-02');
  final _quantityController = TextEditingController(text: '5.0');
  final _batchIdController = TextEditingController();
  final _issuedToController = TextEditingController(text: 'Shift Operator');
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _recordDate = DateTime.now();
  }

  @override
  void dispose() {
    _stockItemIdController.dispose();
    _quantityController.dispose();
    _batchIdController.dispose();
    _issuedToController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(materialRepositoryProvider);
      final qty = double.parse(_quantityController.text.trim());

      final payload = <String, dynamic>{
        'recordDate': _recordDate.toIso8601String().split('T')[0],
        'department': _department.value,
        'stockItemId': _stockItemIdController.text.trim(),
        'quantity': qty,
        if (_batchIdController.text.trim().isNotEmpty)
          'productionBatchId': _batchIdController.text.trim(),
        if (_issuedToController.text.trim().isNotEmpty)
          'issuedTo': _issuedToController.text.trim(),
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      };

      await repo.createIssue(payload);
      ref.invalidate(materialIssuesProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material issue recorded. Stock decremented atomically.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to issue material: $e'),
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
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.outbox_outlined, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Issue Material / Consumable', style: Theme.of(context).textTheme.titleLarge),
                            Text('Deducts stock & posts cost to department', style: Theme.of(context).textTheme.bodySmall),
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
                        child: DropdownButtonFormField<IssueDepartment>(
                          value: _department,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Department *'),
                          items: IssueDepartment.values
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
                              labelText: 'Issue Date',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(_recordDate.toIso8601String().split('T')[0]),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Stock Item ID & Quantity
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _stockItemIdController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Item ID *',
                            hintText: 'item-02, stk-lpg',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Quantity *',
                            hintText: '5.0',
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          validator: (v) {
                            final val = double.tryParse(v ?? '');
                            if (val == null || val <= 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Optional Production Batch ID
                  TextFormField(
                    controller: _batchIdController,
                    decoration: const InputDecoration(
                      labelText: 'Production Batch ID (Optional)',
                      hintText: 'Link directly to batch for batch costing',
                      prefixIcon: Icon(Icons.qr_code_2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Issued To & Notes
                  TextFormField(
                    controller: _issuedToController,
                    decoration: const InputDecoration(
                      labelText: 'Issued To / Operator',
                      hintText: 'Name of technician or operator',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Purpose / Remarks',
                      hintText: 'Routine machine wash, mineral supplementation, etc.',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Action Buttons
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
                        label: Text(_isSubmitting ? 'Issuing...' : 'Issue Material'),
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
