import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../packaging_provider.dart';

class RecordPackagingDialog extends ConsumerStatefulWidget {
  final String? initialBatchId;
  final String? initialBatchNumber;

  const RecordPackagingDialog({
    super.key,
    this.initialBatchId,
    this.initialBatchNumber,
  });

  @override
  ConsumerState<RecordPackagingDialog> createState() => _RecordPackagingDialogState();
}

class _RecordPackagingDialogState extends ConsumerState<RecordPackagingDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _recordDate;

  late final TextEditingController _batchIdController;
  final _packSizeController = TextEditingController(text: '0.5');
  final _numPacksController = TextEditingController(text: '100');
  final _scrapUnitsController = TextEditingController(text: '0');
  final _packagingItemController = TextEditingController(text: 'item-05');
  final _notesController = TextEditingController();

  String _packUnit = 'LITRE';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _recordDate = DateTime.now();
    _batchIdController = TextEditingController(text: widget.initialBatchId ?? '');
  }

  @override
  void dispose() {
    _batchIdController.dispose();
    _packSizeController.dispose();
    _numPacksController.dispose();
    _scrapUnitsController.dispose();
    _packagingItemController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _computedPackagedQty {
    final size = double.tryParse(_packSizeController.text.trim()) ?? 0.0;
    final packs = int.tryParse(_numPacksController.text.trim()) ?? 0;
    return size * packs;
  }

  int get _computedStockDeduction {
    final packs = int.tryParse(_numPacksController.text.trim()) ?? 0;
    final scrap = int.tryParse(_scrapUnitsController.text.trim()) ?? 0;
    return packs + scrap;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(packagingRepositoryProvider);
      final packSize = double.parse(_packSizeController.text.trim());
      final numPacks = int.parse(_numPacksController.text.trim());
      final scrap = int.tryParse(_scrapUnitsController.text.trim()) ?? 0;

      await repo.createRun({
        'recordDate': _recordDate.toIso8601String().split('T')[0],
        'productionBatchId': _batchIdController.text.trim(),
        'packSize': packSize,
        'packUnit': _packUnit,
        'numberOfPacks': numPacks,
        'packagingItemId': _packagingItemController.text.trim(),
        'scrapUnits': scrap,
        'materialConsumed': numPacks + scrap,
        if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
      });

      ref.invalidate(packagingRunsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Packaging run recorded. Material stock & batch quantity deducted.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record packaging run: $e'),
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
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Record Packaging Run', style: Theme.of(context).textTheme.titleLarge),
                            Text('Deducts batch output & packaging inventory', style: Theme.of(context).textTheme.bodySmall),
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

                  // Production Batch ID
                  TextFormField(
                    controller: _batchIdController,
                    decoration: InputDecoration(
                      labelText: 'Production Batch ID *',
                      hintText: 'e.g. UUID or batch reference',
                      prefixIcon: const Icon(Icons.qr_code),
                      helperText: widget.initialBatchNumber != null ? 'Batch: ${widget.initialBatchNumber}' : null,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Batch ID is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Date Picker Row
                  InkWell(
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
                        labelText: 'Packaging Date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(_recordDate.toIso8601String().split('T')[0]),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Pack Size & Unit Row
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _packSizeController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Pack Size *',
                            hintText: '0.5, 1.0',
                            prefixIcon: Icon(Icons.straighten),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final val = double.tryParse(v ?? '');
                            if (val == null || val <= 0) return 'Invalid size';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _packUnit,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'LITRE', child: Text('Litre')),
                            DropdownMenuItem(value: 'KG', child: Text('Kg')),
                            DropdownMenuItem(value: 'POUCH', child: Text('Pouch')),
                            DropdownMenuItem(value: 'BOTTLE', child: Text('Bottle')),
                            DropdownMenuItem(value: 'JAR', child: Text('Jar')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _packUnit = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Number of Packs & Scrap
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _numPacksController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Packs Produced *',
                            hintText: '100',
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final val = int.tryParse(v ?? '');
                            if (val == null || val <= 0) return 'Required';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _scrapUnitsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Scrap / Burst Units',
                            hintText: '0',
                            prefixIcon: Icon(Icons.broken_image_outlined),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final val = int.tryParse(v ?? '');
                            if (val != null && val < 0) return 'Min 0';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Packaging Stock Item ID
                  TextFormField(
                    controller: _packagingItemController,
                    decoration: const InputDecoration(
                      labelText: 'Packaging Item ID *',
                      hintText: 'item-05, stk-pouch-500',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Stock item is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Run Notes (Optional)',
                      hintText: 'Line 1, heat sealer operator notes',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Live Preview Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Packaged Output', style: Theme.of(context).textTheme.bodySmall),
                              Text(
                                '${_computedPackagedQty.toStringAsFixed(2)} $_packUnit',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Packaging Stock Deducted', style: Theme.of(context).textTheme.bodySmall),
                              Text(
                                '$_computedStockDeduction units',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                            ],
                          ),
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
                        label: Text(_isSubmitting ? 'Recording...' : 'Record Run'),
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
