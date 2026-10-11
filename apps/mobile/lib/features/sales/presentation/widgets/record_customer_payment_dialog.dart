import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../sales_provider.dart';
import '../../domain/sales_models.dart';

class RecordCustomerPaymentDialog extends ConsumerStatefulWidget {
  final CustomerModel? initialCustomer;
  final SalesDispatchModel? initialDispatch;

  const RecordCustomerPaymentDialog({
    super.key,
    this.initialCustomer,
    this.initialDispatch,
  });

  @override
  ConsumerState<RecordCustomerPaymentDialog> createState() => _RecordCustomerPaymentDialogState();
}

class _RecordCustomerPaymentDialogState extends ConsumerState<RecordCustomerPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _paymentDate;

  String? _selectedCustomerId;
  String? _selectedDispatchId;

  final _amountController = TextEditingController();
  final _referenceCodeController = TextEditingController();
  final _notesController = TextEditingController();

  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _paymentDate = DateTime.now();

    if (widget.initialCustomer != null) {
      _selectedCustomerId = widget.initialCustomer!.id;
    }

    if (widget.initialDispatch != null) {
      _selectedDispatchId = widget.initialDispatch!.id;
      _selectedCustomerId = widget.initialDispatch!.customerId;
      _amountController.text = widget.initialDispatch!.balanceDue.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(salesRepositoryProvider);

      final amount = double.parse(_amountController.text.trim());

      await repo.createPayment({
        'customerId': _selectedCustomerId,
        if (_selectedDispatchId != null && _selectedDispatchId!.isNotEmpty)
          'dispatchId': _selectedDispatchId,
        'recordDate': _paymentDate.toIso8601String().split('T')[0],
        'amountReceived': amount,
        'paymentMethod': _selectedPaymentMethod.apiValue,
        if (_referenceCodeController.text.trim().isNotEmpty)
          'referenceCode': _referenceCodeController.text.trim(),
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      });

      ref.invalidate(customerPaymentsProvider);
      ref.invalidate(customersProvider);
      ref.invalidate(salesDispatchesProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer payment received and ledger updated.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record payment: $e'),
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
    final customersAsync = ref.watch(customersProvider);
    final dispatchesAsync = ref.watch(salesDispatchesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 650),
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
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.payment, color: AppColors.secondary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          'Record Customer Payment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Customer selection
                  customersAsync.when(
                    data: (customers) {
                      return DropdownButtonFormField<String>(
                        value: _selectedCustomerId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Customer *',
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: customers.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              '${c.name} (Bal: ₹${c.currentBalance.toStringAsFixed(2)})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCustomerId = val;
                          });
                        },
                        validator: (v) => v == null ? 'Please select a customer' : null,
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (err, _) => Text('Error loading customers: $err',
                        style: const TextStyle(color: AppColors.error)),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Optional Dispatch selection
                  dispatchesAsync.when(
                    data: (dispatchesData) {
                      final customerDispatches = _selectedCustomerId == null
                          ? dispatchesData.items
                          : dispatchesData.items.where((d) => d.customerId == _selectedCustomerId).toList();

                      return DropdownButtonFormField<String?>(
                        value: _selectedDispatchId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Allocate to Dispatch (Optional)',
                          prefixIcon: Icon(Icons.receipt),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('General Account Payment (Unallocated)', overflow: TextOverflow.ellipsis),
                          ),
                          ...customerDispatches.map((d) {
                            return DropdownMenuItem<String?>(
                              value: d.id,
                              child: Text(
                                '${d.dispatchNumber} - ₹${d.totalAmount.toStringAsFixed(2)} (Due: ₹${d.balanceDue.toStringAsFixed(2)})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedDispatchId = val;
                            if (val != null) {
                              final matched = customerDispatches.firstWhere((d) => d.id == val);
                              if (matched.balanceDue > 0) {
                                _amountController.text = matched.balanceDue.toStringAsFixed(2);
                              }
                            }
                          });
                        },
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Payment Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _paymentDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) setState(() => _paymentDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Payment Date *',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${_paymentDate.year}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Amount received & Payment method
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Amount Paid (₹) *',
                            prefixIcon: Icon(Icons.currency_rupee),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Amount required';
                            final parsed = double.tryParse(v);
                            if (parsed == null || parsed <= 0) return 'Must be > 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: DropdownButtonFormField<PaymentMethod>(
                          value: _selectedPaymentMethod,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Method *',
                            prefixIcon: Icon(Icons.credit_card),
                          ),
                          items: PaymentMethod.values.map((pm) {
                            return DropdownMenuItem(
                              value: pm,
                              child: Text(pm.label, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPaymentMethod = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Reference code
                  TextFormField(
                    controller: _referenceCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Reference Code / Cheque No / UPI ID',
                      prefixIcon: Icon(Icons.tag),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Payment Notes',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Record Payment'),
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
