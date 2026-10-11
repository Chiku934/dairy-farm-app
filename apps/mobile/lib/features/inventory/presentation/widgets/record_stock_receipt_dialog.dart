import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../inventory_provider.dart';
import '../../domain/inventory_models.dart';

class RecordStockReceiptDialog extends ConsumerStatefulWidget {
  final String? initialStockItemId;

  const RecordStockReceiptDialog({super.key, this.initialStockItemId});

  @override
  ConsumerState<RecordStockReceiptDialog> createState() => _RecordStockReceiptDialogState();
}

class _RecordStockReceiptDialogState extends ConsumerState<RecordStockReceiptDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _recordDate;

  String? _selectedItemId;
  String? _selectedSupplierId;
  final _quantityController = TextEditingController(text: '100');
  final _unitPriceController = TextEditingController(text: '25.0');
  final _supplierLotController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _recordDate = DateTime.now();
    _selectedItemId = widget.initialStockItemId;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _supplierLotController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _computedTotalCost {
    final qty = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final price = double.tryParse(_unitPriceController.text.trim()) ?? 0.0;
    return qty * price;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an inventory stock item.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final qty = double.parse(_quantityController.text.trim());
      final price = double.parse(_unitPriceController.text.trim());

      await repo.createReceipt({
        'recordDate': _recordDate.toIso8601String().split('T')[0],
        'stockItemId': _selectedItemId,
        if (_selectedSupplierId != null) 'supplierId': _selectedSupplierId,
        'quantity': qty,
        'unitPrice': price,
        if (_supplierLotController.text.trim().isNotEmpty)
          'supplierLot': _supplierLotController.text.trim(),
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      });

      ref.invalidate(inventoryItemsProvider);
      ref.invalidate(stockReceiptsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inbound receipt recorded. Weighted average cost updated.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record stock receipt: $e'),
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
    final itemsAsync = ref.watch(inventoryItemsProvider);
    final suppliersAsync = ref.watch(suppliersProvider);

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
                        child: const Icon(Icons.input_outlined, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Record Inbound Receipt', style: Theme.of(context).textTheme.titleLarge),
                            Text('Updates stock balance and recalculates WAC', style: Theme.of(context).textTheme.bodySmall),
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

                  // Stock Item Dropdown
                  itemsAsync.when(
                    data: (data) {
                      final items = data.items;
                      return DropdownButtonFormField<String>(
                        value: _selectedItemId,
                        decoration: const InputDecoration(
                          labelText: 'Stock Item *',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: items.map((i) {
                          return DropdownMenuItem(
                            value: i.id,
                            child: Text('${i.name} (${i.currentStock} ${i.unit})'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedItemId = val),
                        validator: (v) => v == null ? 'Stock item is required' : null,
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Failed to load items: $e'),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Supplier Selection Dropdown
                  suppliersAsync.when(
                    data: (suppliers) {
                      return DropdownButtonFormField<String>(
                        value: _selectedSupplierId,
                        decoration: const InputDecoration(
                          labelText: 'Supplier (Optional)',
                          prefixIcon: Icon(Icons.local_shipping_outlined),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None / Spot Vendor')),
                          ...suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                        ],
                        onChanged: (val) => setState(() => _selectedSupplierId = val),
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Date Picker
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
                        labelText: 'Receipt Date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(_recordDate.toIso8601String().split('T')[0]),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Quantity & Unit Price Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Quantity *',
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final n = double.tryParse(v.trim());
                            if (n == null || n <= 0) return '> 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _unitPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Unit Price (₹) *',
                            prefixIcon: Icon(Icons.currency_rupee),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final n = double.tryParse(v.trim());
                            if (n == null || n <= 0) return '> 0';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Supplier Lot / Delivery Challan
                  TextFormField(
                    controller: _supplierLotController,
                    decoration: const InputDecoration(
                      labelText: 'Supplier Lot / Invoice #',
                      prefixIcon: Icon(Icons.tag),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Cost Calculation Preview Card
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
                        const Text('Total Inbound Cost:'),
                        Text(
                          '₹${_computedTotalCost.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                        ),
                      ],
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
                        label: Text(_isSubmitting ? 'Recording...' : 'Record Receipt'),
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
