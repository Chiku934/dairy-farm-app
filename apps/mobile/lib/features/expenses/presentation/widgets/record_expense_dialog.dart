import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../domain/expense_models.dart';
import '../expense_provider.dart';

class RecordExpenseDialog extends ConsumerStatefulWidget {
  const RecordExpenseDialog({super.key});

  @override
  ConsumerState<RecordExpenseDialog> createState() => _RecordExpenseDialogState();
}

class _RecordExpenseDialogState extends ConsumerState<RecordExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _payeeController = TextEditingController();
  final _invoiceNumController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  CostCentre _selectedCostCentre = CostCentre.farm;
  ExpenseCategory _selectedCategory = ExpenseCategory.maintenance;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _payeeController.dispose();
    _invoiceNumController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final payload = {
        'recordDate': _selectedDate.toIso8601String().split('T')[0],
        'costCentre': _selectedCostCentre.apiValue,
        'category': _selectedCategory.apiValue,
        'amount': double.parse(_amountController.text),
        if (_payeeController.text.trim().isNotEmpty) 'payee': _payeeController.text.trim(),
        if (_invoiceNumController.text.trim().isNotEmpty) 'invoiceNumber': _invoiceNumController.text.trim(),
        'paymentMethod': _selectedPaymentMethod.apiValue,
        if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
      };

      await ref.read(expenseRepositoryProvider).createExpense(payload);
      ref.invalidate(operatingExpensesProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Operating expense entry saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record expense: $e'),
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
      title: const Text('Record Operating Expense'),
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

                // Cost Centre & Category Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<CostCentre>(
                        value: _selectedCostCentre,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Cost Centre',
                          border: OutlineInputBorder(),
                        ),
                        items: CostCentre.values.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(c.label, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCostCentre = val);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: DropdownButtonFormField<ExpenseCategory>(
                        value: _selectedCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Expense Category',
                          border: OutlineInputBorder(),
                        ),
                        items: ExpenseCategory.values.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat.label, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Amount & Payment Method
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppTextField(
                        controller: _amountController,
                        label: 'Amount (₹)',
                        hint: 'e.g. 1500.00',
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
                      flex: 2,
                      child: DropdownButtonFormField<PaymentMethod>(
                        value: _selectedPaymentMethod,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Payment Mode',
                          border: OutlineInputBorder(),
                        ),
                        items: PaymentMethod.values.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(p.label, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPaymentMethod = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Payee / Vendor & Invoice Number
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _payeeController,
                        label: 'Payee / Vendor Name',
                        hint: 'e.g. Local Agro Spares Dandiri',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        controller: _invoiceNumController,
                        label: 'Invoice / Bill No. (optional)',
                        hint: 'e.g. INV-9842',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Notes
                AppTextField(
                  controller: _notesController,
                  label: 'Expense Description / Remarks',
                  hint: 'Purpose of expenditure, purchase order details...',
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
              : const Text('Record Expense'),
        ),
      ],
    );
  }
}
