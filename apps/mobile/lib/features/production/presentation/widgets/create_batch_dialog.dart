import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/production_models.dart';
import '../production_provider.dart';

class CreateBatchDialog extends ConsumerStatefulWidget {
  const CreateBatchDialog({super.key});

  @override
  ConsumerState<CreateBatchDialog> createState() => _CreateBatchDialogState();
}

class _CreateBatchDialogState extends ConsumerState<CreateBatchDialog> {
  final _formKey = GlobalKey<FormState>();

  ProductType _productType = ProductType.paneer;
  late DateTime _selectedDate;
  late DateTime _expiryDate;

  final _consumedMilkController = TextEditingController(text: '100');
  final _finishedQtyController = TextEditingController(text: '18');
  final _lpgController = TextEditingController(text: '2.0');
  final _byproductController = TextEditingController(text: '80.0');
  final _operatorController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _expiryDate = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _consumedMilkController.dispose();
    _finishedQtyController.dispose();
    _lpgController.dispose();
    _byproductController.dispose();
    _operatorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _currentYield {
    final milk = double.tryParse(_consumedMilkController.text.trim()) ?? 0;
    final finished = double.tryParse(_finishedQtyController.text.trim()) ?? 0;
    if (milk <= 0) return 0;
    return (finished / milk) * 100;
  }

  String get _expectedYieldGuide {
    switch (_productType) {
      case ProductType.paneer:
        return 'Standard: 14% - 22% (Max cap 25%)';
      case ProductType.khoya:
        return 'Standard: 16% - 24% (Max cap 28%)';
      case ProductType.ghee:
        return 'Standard: 5.0% - 7.5% (Max cap 9%)';
      case ProductType.dahi:
        return 'Standard: 92% - 100% (Max cap 100%)';
      case ProductType.butter:
        return 'Standard: 5.5% - 9.5% (Max cap 11%)';
      case ProductType.milk:
        return 'Standard: 95% - 100% (Max cap 102%)';
      case ProductType.biogasFertiliser:
        return 'Variable based on slurry digestion';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final milk = double.tryParse(_consumedMilkController.text.trim());
    final finished = double.tryParse(_finishedQtyController.text.trim());

    if (milk == null || milk <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid milk consumed in litres.')),
      );
      return;
    }
    if (finished == null || finished <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid finished quantity.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = <String, dynamic>{
        'recordDate': _selectedDate.toIso8601String().split('T')[0],
        'shift': 'AM',
        'productType': _productType.value,
        'bmcMilkConsumedL': milk,
        'finishedQuantity': finished,
        'unitOfMeasure': _productType.defaultUnit,
        'expiryDate': _expiryDate.toIso8601String().split('T')[0],
        'qualityRelease': QualityReleaseStatus.hold.value,
        'status': BatchStatus.completed.value,
      };

      final lpg = double.tryParse(_lpgController.text.trim());
      if (lpg != null && lpg > 0) payload['lpgUsedKg'] = lpg;

      final byprod = double.tryParse(_byproductController.text.trim());
      if (byprod != null && byprod > 0) payload['byproductQuantityKg'] = byprod;

      if (_operatorController.text.trim().isNotEmpty) {
        payload['operatorName'] = _operatorController.text.trim();
      }
      if (_notesController.text.trim().isNotEmpty) {
        payload['notes'] = _notesController.text.trim();
      }

      final repo = ref.read(productionRepositoryProvider);
      await repo.createBatch(payload);

      ref.invalidate(productionBatchesProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Production batch created successfully. Milk & LPG stock deducted.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating batch: $e'),
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
    final yieldVal = _currentYield;

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
                    Text('New Production Batch', style: AppTypography.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Product Selection
                DropdownButtonFormField<ProductType>(
                  value: _productType,
                  decoration: const InputDecoration(
                    labelText: 'Product Type *',
                    prefixIcon: Icon(Icons.blender_outlined),
                  ),
                  items: ProductType.values
                      .map((p) => DropdownMenuItem(value: p, child: Text('${p.label} (${p.defaultUnit})')))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _productType = val;
                        // Update default expiry based on product
                        if (val == ProductType.paneer || val == ProductType.dahi) {
                          _expiryDate = DateTime.now().add(const Duration(days: 7));
                        } else if (val == ProductType.milk) {
                          _expiryDate = DateTime.now().add(const Duration(days: 3));
                        } else if (val == ProductType.ghee) {
                          _expiryDate = DateTime.now().add(const Duration(days: 180));
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Date & Expiry Row
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
                            labelText: 'Batch Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(_selectedDate.toIso8601String().split('T')[0]),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _expiryDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) setState(() => _expiryDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Expiry Date',
                            prefixIcon: Icon(Icons.event_busy_outlined),
                          ),
                          child: Text(_expiryDate.toIso8601String().split('T')[0]),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Milk Consumed & Finished Quantity
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _consumedMilkController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Milk Consumed (L) *',
                          hintText: '100',
                          prefixIcon: Icon(Icons.water_drop_outlined),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Milk is required' : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _finishedQtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Finished Output (${_productType.defaultUnit}) *',
                          hintText: '18',
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Quantity is required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Live Yield Calculation Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Live Conversion Yield:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            '${yieldVal.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: yieldVal > 0 ? AppColors.primary : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _expectedYieldGuide,
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // LPG & By-products Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lpgController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'LPG Used (kg)',
                          hintText: '2.0',
                          prefixIcon: Icon(Icons.local_fire_department_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _byproductController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'By-Product (kg)',
                          hintText: 'e.g. Whey / Buttermilk',
                          prefixIcon: Icon(Icons.recycling_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Operator & Notes
                TextFormField(
                  controller: _operatorController,
                  decoration: const InputDecoration(
                    labelText: 'Processing Operator',
                    hintText: 'Operator name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Batch Process Notes',
                    hintText: 'Recipe parameters, culture details...',
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
                      label: const Text('Create Batch'),
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
