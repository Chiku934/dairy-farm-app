import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../inventory_provider.dart';
import '../../domain/inventory_models.dart';

class AddStockItemDialog extends ConsumerStatefulWidget {
  const AddStockItemDialog({super.key});

  @override
  ConsumerState<AddStockItemDialog> createState() => _AddStockItemDialogState();
}

class _AddStockItemDialogState extends ConsumerState<AddStockItemDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _unitController = TextEditingController(text: 'kg');
  final _initialStockController = TextEditingController(text: '0.0');
  final _initialPriceController = TextEditingController(text: '0.0');
  final _reorderLevelController = TextEditingController(text: '50.0');
  final _notesController = TextEditingController();

  StockCategory _selectedCategory = StockCategory.feed;
  String _selectedUsedBy = 'BOTH';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _initialStockController.dispose();
    _initialPriceController.dispose();
    _reorderLevelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);

      await repo.createItem({
        'name': _nameController.text.trim(),
        'category': _selectedCategory.apiValue,
        'usedBy': _selectedUsedBy,
        'unit': _unitController.text.trim(),
        'initialStock': double.tryParse(_initialStockController.text.trim()) ?? 0.0,
        'initialPrice': double.tryParse(_initialPriceController.text.trim()) ?? 0.0,
        'reorderLevel': double.tryParse(_reorderLevelController.text.trim()) ?? 0.0,
        if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
      });

      ref.invalidate(inventoryItemsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock item created successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create stock item: $e'),
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
                        child: const Icon(Icons.add_box_outlined, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Add Stock Item', style: Theme.of(context).textTheme.titleLarge),
                            Text('Register raw material, packaging or consumable', style: Theme.of(context).textTheme.bodySmall),
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

                  // Item Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name *',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Item name is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Category & Used By Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<StockCategory>(
                          value: _selectedCategory,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: StockCategory.values.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c.label, overflow: TextOverflow.ellipsis));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedUsedBy,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Used By *',
                            prefixIcon: Icon(Icons.apartment_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'BOTH', child: Text('Farm & Production', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'FARM', child: Text('Farm Only', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'PRODUCTION', child: Text('Production Only', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'BIOGAS', child: Text('Biogas Only', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedUsedBy = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Unit of Measure & Reorder Level
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _unitController,
                          decoration: const InputDecoration(
                            labelText: 'Unit (e.g. kg, L, units) *',
                            prefixIcon: Icon(Icons.straighten),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _reorderLevelController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Reorder Level *',
                            prefixIcon: Icon(Icons.warning_amber_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Initial Stock & Initial Price Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _initialStockController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Initial Stock',
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _initialPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Initial Cost (₹)',
                            prefixIcon: Icon(Icons.currency_rupee),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Buttons
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
                        label: Text(_isSubmitting ? 'Saving...' : 'Create Item'),
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
