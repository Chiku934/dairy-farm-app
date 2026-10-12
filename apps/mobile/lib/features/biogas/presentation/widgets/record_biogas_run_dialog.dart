import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../domain/biogas_models.dart';
import '../biogas_provider.dart';

class RecordBiogasRunDialog extends ConsumerStatefulWidget {
  const RecordBiogasRunDialog({super.key});

  @override
  ConsumerState<RecordBiogasRunDialog> createState() => _RecordBiogasRunDialogState();
}

class _RecordBiogasRunDialogState extends ConsumerState<RecordBiogasRunDialog> {
  final _formKey = GlobalKey<FormState>();
  final _slurryController = TextEditingController();
  final _dryOutputController = TextEditingController();
  final _moistureController = TextEditingController(text: '15.0');
  final _buyerOrPlotController = TextEditingController();
  final _saleAmountController = TextEditingController();
  final _notesController = TextEditingController();

  final _bags1kgController = TextEditingController(text: '0');
  final _bags5kgController = TextEditingController(text: '0');
  final _bags25kgController = TextEditingController(text: '0');
  final _bags50kgController = TextEditingController(text: '0');

  late DateTime _selectedDate;
  BiogasUsageType _selectedUsage = BiogasUsageType.storeStock;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _slurryController.dispose();
    _dryOutputController.dispose();
    _moistureController.dispose();
    _buyerOrPlotController.dispose();
    _saleAmountController.dispose();
    _notesController.dispose();
    _bags1kgController.dispose();
    _bags5kgController.dispose();
    _bags25kgController.dispose();
    _bags50kgController.dispose();
    super.dispose();
  }

  double get _totalPackedKg {
    final b1 = int.tryParse(_bags1kgController.text) ?? 0;
    final b5 = int.tryParse(_bags5kgController.text) ?? 0;
    final b25 = int.tryParse(_bags25kgController.text) ?? 0;
    final b50 = int.tryParse(_bags50kgController.text) ?? 0;
    return (b1 * 1.0) + (b5 * 5.0) + (b25 * 25.0) + (b50 * 50.0);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final dryOutput = double.tryParse(_dryOutputController.text) ?? 0.0;
    final packed = _totalPackedKg;
    if (packed > dryOutput) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Total packed bags ($packed kg) cannot exceed dry fertiliser output ($dryOutput kg)',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = {
        'recordDate': _selectedDate.toIso8601String().split('T')[0],
        'slurryInputKg': double.parse(_slurryController.text),
        'dryFertiliserOutputKg': dryOutput,
        'moisturePct': double.tryParse(_moistureController.text) ?? 15.0,
        'usageType': _selectedUsage.apiValue,
        if (_buyerOrPlotController.text.trim().isNotEmpty)
          'buyerOrFarmPlot': _buyerOrPlotController.text.trim(),
        if (_selectedUsage == BiogasUsageType.directSale && _saleAmountController.text.isNotEmpty)
          'saleAmount': double.tryParse(_saleAmountController.text),
        'bagsPacked1kg': int.tryParse(_bags1kgController.text) ?? 0,
        'bagsPacked5kg': int.tryParse(_bags5kgController.text) ?? 0,
        'bagsPacked25kg': int.tryParse(_bags25kgController.text) ?? 0,
        'bagsPacked50kg': int.tryParse(_bags50kgController.text) ?? 0,
        if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
      };

      await ref.read(biogasRepositoryProvider).createRun(payload);
      ref.invalidate(biogasRunsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biogas fertiliser production run recorded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record run: $e'),
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
    return AlertDialog(
      title: const Text('Record Biogas Run & Output'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date picker row
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

                // Slurry Input & Dry Output
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _slurryController,
                        label: 'Slurry Input (kg)',
                        hint: 'e.g. 1000',
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
                      child: AppTextField(
                        controller: _dryOutputController,
                        label: 'Dry Output (kg)',
                        hint: 'e.g. 180',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final n = double.tryParse(v);
                          if (n == null || n < 0) return '>= 0 required';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Moisture % & Usage Type
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: AppTextField(
                        controller: _moistureController,
                        label: 'Moisture (%)',
                        hint: '15.0',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<BiogasUsageType>(
                        value: _selectedUsage,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Disposition / Usage Type',
                          border: OutlineInputBorder(),
                        ),
                        items: BiogasUsageType.values.map((u) {
                          return DropdownMenuItem(
                            value: u,
                            child: Text(u.label, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedUsage = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Destination/buyer and sale amount
                if (_selectedUsage == BiogasUsageType.directSale) ...[
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _buyerOrPlotController,
                          label: 'Buyer Name',
                          hint: 'e.g. Kisan Agro Nursery',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppTextField(
                          controller: _saleAmountController,
                          label: 'Sale Amount (₹)',
                          hint: 'e.g. 1800',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ] else if (_selectedUsage == BiogasUsageType.internalFarm) ...[
                  AppTextField(
                    controller: _buyerOrPlotController,
                    label: 'Target Farm Plot / Sector',
                    hint: 'e.g. Fodder Plot B (Napier Grass)',
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Bagging Breakdown Section
                Text(
                  'Packaged Bags Breakdown (optional)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Total packed: ${_totalPackedKg.toStringAsFixed(1)} kg',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _totalPackedKg > (double.tryParse(_dryOutputController.text) ?? 0.0)
                        ? AppColors.error
                        : AppColors.neutralSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _bags1kgController,
                        label: '1 kg Bags',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppTextField(
                        controller: _bags5kgController,
                        label: '5 kg Bags',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppTextField(
                        controller: _bags25kgController,
                        label: '25 kg Bags',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppTextField(
                        controller: _bags50kgController,
                        label: '50 kg Bags',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Notes
                AppTextField(
                  controller: _notesController,
                  label: 'Remarks / Batch Notes',
                  hint: 'Solar drying bed conditions, quality remarks...',
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
              : const Text('Record Run'),
        ),
      ],
    );
  }
}
