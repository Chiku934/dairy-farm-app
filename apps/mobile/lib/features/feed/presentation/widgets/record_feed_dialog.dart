import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../feed_provider.dart';
import '../../domain/feed_models.dart';

class RecordFeedDialog extends ConsumerStatefulWidget {
  const RecordFeedDialog({super.key});

  @override
  ConsumerState<RecordFeedDialog> createState() => _RecordFeedDialogState();
}

class _RecordFeedDialogState extends ConsumerState<RecordFeedDialog> {
  final _formKey = GlobalKey<FormState>();
  final _earTagController = TextEditingController();
  final _groupController = TextEditingController();
  final _quantityController = TextEditingController(text: '7.0');
  final _notesController = TextEditingController();

  bool _isGroup = false;
  String _selectedDate = DateTime.now().toIso8601String().split('T')[0];
  String _selectedStockItem = 'stk-conc';
  FeedType _feedType = FeedType.concentrate;
  FeedShift _shift = FeedShift.allDay;
  bool _isSubmitting = false;

  final List<Map<String, String>> _availableStockItems = [
    {'id': 'stk-conc', 'name': 'Standard Cattle Concentrate Pellets', 'type': 'CONCENTRATE'},
    {'id': 'stk-green', 'name': 'Green Napier Grass / Fodder', 'type': 'GREEN_FODDER'},
    {'id': 'stk-dry', 'name': 'Dry Wheat Straw / Bhusa', 'type': 'DRY_FODDER'},
    {'id': 'item-01', 'name': 'Crushed Maize Grain', 'type': 'MAIZE'},
    {'id': 'item-02', 'name': 'Mineral Mixture', 'type': 'MINERAL_MIXTURE'},
    {'id': 'item-03', 'name': 'Feed Salt', 'type': 'SALT'},
  ];

  @override
  void dispose() {
    _earTagController.dispose();
    _groupController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = double.tryParse(_quantityController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid feed quantity greater than 0 kg.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(feedRepositoryProvider);
      await repo.recordFeedConsumption(
        animalId: _isGroup ? null : _earTagController.text.trim(),
        groupName: _isGroup ? _groupController.text.trim() : null,
        recordDate: _selectedDate,
        stockItemId: _selectedStockItem,
        quantityKg: qty,
        feedType: _feedType,
        shift: _shift,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (mounted) {
        ref.invalidate(feedEntriesProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feed consumption issued and stock deducted successfully!'),
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
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
                    Text('Issue Cattle Feed', style: AppTypography.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Individual Cow'), icon: Icon(Icons.pets)),
                    ButtonSegment(value: true, label: Text('Group / Herd'), icon: Icon(Icons.groups)),
                  ],
                  selected: {_isGroup},
                  onSelectionChanged: (val) => setState(() => _isGroup = val.first),
                ),
                const SizedBox(height: AppSpacing.md),

                if (!_isGroup) ...[
                  TextFormField(
                    controller: _earTagController,
                    decoration: const InputDecoration(
                      labelText: 'Cow Tag / ID *',
                      hintText: 'e.g. c-01 or 210385',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Cow Tag is required' : null,
                  ),
                ] else ...[
                  TextFormField(
                    controller: _groupController,
                    decoration: const InputDecoration(
                      labelText: 'Group Designation *',
                      hintText: 'e.g. Lactating Herd A',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Group name is required' : null,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),

                // Feed Stock Item Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedStockItem,
                  decoration: const InputDecoration(
                    labelText: 'Feed Inventory Item',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  items: _availableStockItems
                      .map((item) => DropdownMenuItem(
                            value: item['id'],
                            child: Text(item['name']!, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStockItem = val;
                        final matched = _availableStockItems.firstWhere((i) => i['id'] == val);
                        _feedType = FeedType.fromString(matched['type']);
                      });
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Quantity & Shift
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Quantity (kg) *',
                          hintText: '7.0',
                          prefixIcon: Icon(Icons.scale_outlined),
                          suffixText: 'kg',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Quantity is required';
                          final n = double.tryParse(v.trim());
                          if (n == null || n <= 0) return 'Must be > 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DropdownButtonFormField<FeedShift>(
                        value: _shift,
                        decoration: const InputDecoration(
                          labelText: 'Feeding Shift',
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        items: FeedShift.values
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _shift = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.parse(_selectedDate),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked.toIso8601String().split('T')[0]);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Feeding Date',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(_selectedDate, style: AppTypography.bodyMedium),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Ration observations or adjustments',
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
                      label: const Text('Issue Feed'),
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
