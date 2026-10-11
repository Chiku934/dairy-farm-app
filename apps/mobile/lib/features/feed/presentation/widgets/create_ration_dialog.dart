import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../feed_provider.dart';
import '../../domain/feed_models.dart';

class CreateRationDialog extends ConsumerStatefulWidget {
  const CreateRationDialog({super.key});

  @override
  ConsumerState<CreateRationDialog> createState() => _CreateRationDialogState();
}

class _CreateRationDialogState extends ConsumerState<CreateRationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController(text: 'RATION-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
  final _descriptionController = TextEditingController();

  TargetAnimalStage _targetStage = TargetAnimalStage.lactating;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _items = [
    {'stockItemId': 'stk-conc', 'name': 'Concentrate Pellets (₹24.50/kg)', 'price': 24.50, 'qty': 6.0},
    {'stockItemId': 'stk-green', 'name': 'Green Fodder (₹3.50/kg)', 'price': 3.50, 'qty': 20.0},
    {'stockItemId': 'stk-dry', 'name': 'Dry Straw / Bhusa (₹6.00/kg)', 'price': 6.00, 'qty': 5.0},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double get _totalQty => _items.fold(0.0, (sum, i) => sum + (i['qty'] as double));
  double get _totalCost => _items.fold(0.0, (sum, i) => sum + ((i['qty'] as double) * (i['price'] as double)));
  double get _unitCostPerKg => _totalQty > 0 ? _totalCost / _totalQty : 0.0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty || _totalQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please configure at least one feed ingredient.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(feedRepositoryProvider);
      await repo.createRation(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        targetStage: _targetStage,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        items: _items.map((i) => {
          'stockItemId': i['stockItemId'],
          'quantityKg': i['qty'],
        }).toList(),
      );

      if (mounted) {
        ref.invalidate(rationsProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ration formulation created successfully!'),
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
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
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
                    Text('New Ration Formulation', style: AppTypography.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ration Title *',
                    hintText: 'e.g. High-Yielding Lactating TMR',
                    prefixIcon: Icon(Icons.menu_book),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ration title is required' : null,
                ),
                const SizedBox(height: AppSpacing.md),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Ration Code *',
                          hintText: 'RATION-LACT-HIGH',
                          prefixIcon: Icon(Icons.tag),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Code is required' : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DropdownButtonFormField<TargetAnimalStage>(
                        value: _targetStage,
                        decoration: const InputDecoration(
                          labelText: 'Target Stage',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: TargetAnimalStage.values
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.label, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _targetStage = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Live Costing Preview Card
                Card(
                  color: AppColors.primary.withOpacity(0.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Calculated Formulation Costing', style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Diet Quantity: ${_totalQty.toStringAsFixed(1)} kg', style: AppTypography.bodySmall),
                            Text('Total Cost: ₹${_totalCost.toStringAsFixed(2)}', style: AppTypography.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Unit Cost: ₹${_unitCostPerKg.toStringAsFixed(2)} / kg',
                          style: AppTypography.titleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Ingredients Configuration (kg/cow/day)', style: AppTypography.titleMedium),
                const SizedBox(height: 8),

                ..._items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(item['name'] as String, style: AppTypography.bodySmall),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: item['qty'].toString(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              isDense: true,
                              suffixText: 'kg',
                            ),
                            onChanged: (val) {
                              final d = double.tryParse(val) ?? 0.0;
                              setState(() => _items[idx]['qty'] = d);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Feeding Instructions',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.lg),

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
                      label: const Text('Save Formulation'),
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
