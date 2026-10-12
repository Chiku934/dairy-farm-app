import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../inventory/presentation/inventory_provider.dart';
import '../../domain/wastage_models.dart';
import '../wastage_provider.dart';

class RecordWastageDialog extends ConsumerStatefulWidget {
  const RecordWastageDialog({super.key});

  @override
  ConsumerState<RecordWastageDialog> createState() => _RecordWastageDialogState();
}

class _RecordWastageDialogState extends ConsumerState<RecordWastageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _refIdController = TextEditingController();
  final _qtyController = TextEditingController();
  final _unitController = TextEditingController(text: 'L');
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  StockType _selectedStockType = StockType.bmc;
  WastageReason _selectedReason = WastageReason.spoilage;
  String? _selectedStockItemId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _refIdController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onStockTypeChanged(StockType type) {
    setState(() {
      _selectedStockType = type;
      if (type == StockType.bmc) {
        _unitController.text = 'L';
        _refIdController.text = 'BMC-SILO-01';
      } else if (type == StockType.supply) {
        _unitController.text = 'PCS';
        _refIdController.text = '';
      } else {
        _unitController.text = 'KG';
        _refIdController.text = '';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStockType == StockType.supply && _selectedStockItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the inventory stock item to write off.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = {
        'recordDate': _selectedDate.toIso8601String().split('T')[0],
        'stockType': _selectedStockType.apiValue,
        if (_selectedStockItemId != null) 'stockItemId': _selectedStockItemId,
        'referenceId': _refIdController.text.trim(),
        'quantityLost': double.parse(_qtyController.text),
        'unit': _unitController.text.trim().toUpperCase(),
        'reason': _selectedReason.apiValue,
        if (_costController.text.isNotEmpty)
          'estimatedLossCost': double.parse(_costController.text),
        if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
      };

      await ref.read(wastageRepositoryProvider).recordWastage(payload);
      ref.invalidate(wastageRecordsProvider);
      ref.invalidate(inventoryItemsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wastage & loss incident recorded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record wastage: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockItemsAsync = ref.watch(inventoryItemsProvider);

    return AlertDialog(
      title: const Text('Record Wastage & Loss Incident'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date picker
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Date: ${_selectedDate.toIso8601String().split('T')[0]}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Change Date'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Stock Type Dropdown
                DropdownButtonFormField<StockType>(
                  value: _selectedStockType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Loss Stock Type',
                    border: OutlineInputBorder(),
                  ),
                  items: StockType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.label, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) _onStockTypeChanged(val);
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // If SUPPLY -> Select Inventory Item
                if (_selectedStockType == StockType.supply) ...[
                  stockItemsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Failed to load items: $e', style: const TextStyle(color: AppColors.error)),
                    data: (data) {
                      return DropdownButtonFormField<String>(
                        value: _selectedStockItemId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Inventory Stock Item',
                          border: OutlineInputBorder(),
                        ),
                        items: data.items.map((item) {
                          return DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              '${item.name} (Stock: ${item.currentStock} ${item.unit})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedStockItemId = val;
                            final selected = data.items.firstWhere((i) => i.id == val);
                            _unitController.text = selected.unit;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Reference ID & Reason
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _refIdController,
                        label: 'Reference ID / Batch / Silo',
                        hint: 'e.g. SILO-TANK-01 or BATCH-PAN-01',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: DropdownButtonFormField<WastageReason>(
                        value: _selectedReason,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Loss',
                          border: OutlineInputBorder(),
                        ),
                        items: WastageReason.values.map((r) {
                          return DropdownMenuItem(
                            value: r,
                            child: Text(r.label, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedReason = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Quantity & Unit
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        controller: _qtyController,
                        label: 'Quantity Lost',
                        hint: 'e.g. 15.0',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final n = double.tryParse(v);
                          if (n == null || n <= 0) return '> 0 required';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 1,
                      child: AppTextField(
                        controller: _unitController,
                        label: 'Unit',
                        hint: 'L / KG / PCS',
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Estimated Loss Cost (optional)
                AppTextField(
                  controller: _costController,
                  label: 'Estimated Loss Cost (₹, optional)',
                  hint: 'Auto-calculated if blank (@ unit cost or ₹32/L milk)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: AppSpacing.md),

                // Remarks
                AppTextField(
                  controller: _notesController,
                  label: 'Root Cause / Investigation Remarks',
                  hint: 'Details of incident, disposal method, preventative action...',
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Record Wastage'),
        ),
      ],
    );
  }
}
