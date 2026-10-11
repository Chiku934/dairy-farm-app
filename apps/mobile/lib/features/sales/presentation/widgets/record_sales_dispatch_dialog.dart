import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../sales_provider.dart';
import '../../domain/sales_models.dart';

class RecordSalesDispatchDialog extends ConsumerStatefulWidget {
  final SalesOrderModel? initialOrder;

  const RecordSalesDispatchDialog({
    super.key,
    this.initialOrder,
  });

  @override
  ConsumerState<RecordSalesDispatchDialog> createState() => _RecordSalesDispatchDialogState();
}

class _RecordSalesDispatchDialogState extends ConsumerState<RecordSalesDispatchDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _dispatchDate;

  String? _selectedCustomerId;
  String? _selectedOrderId;
  ProductType _selectedProductType = ProductType.milk;

  final _packsSoldController = TextEditingController(text: '10');
  final _pricePerPackController = TextEditingController(text: '32.00');
  final _amountReceivedController = TextEditingController(text: '0.00');
  final _notesController = TextEditingController();

  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _dispatchDate = DateTime.now();

    if (widget.initialOrder != null) {
      _selectedOrderId = widget.initialOrder!.id;
      _selectedCustomerId = widget.initialOrder!.customerId;
      if (widget.initialOrder!.items.isNotEmpty) {
        final firstItem = widget.initialOrder!.items.first;
        _selectedProductType = firstItem.productType;
        final remaining = firstItem.quantityOrdered - firstItem.quantityDispatched;
        _packsSoldController.text = (remaining > 0 ? remaining : firstItem.quantityOrdered).toString();
        _pricePerPackController.text = firstItem.unitPrice.toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _packsSoldController.dispose();
    _pricePerPackController.dispose();
    _amountReceivedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _computedTotalAmount {
    final qty = int.tryParse(_packsSoldController.text.trim()) ?? 0;
    final price = double.tryParse(_pricePerPackController.text.trim()) ?? 0.0;
    return qty * price;
  }

  double get _computedBalanceDue {
    final total = _computedTotalAmount;
    final received = double.tryParse(_amountReceivedController.text.trim()) ?? 0.0;
    final bal = total - received;
    return bal < 0 ? 0.0 : bal;
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

      final packs = int.parse(_packsSoldController.text.trim());
      final price = double.parse(_pricePerPackController.text.trim());
      final received = double.tryParse(_amountReceivedController.text.trim()) ?? 0.0;

      await repo.createDispatch({
        'customerId': _selectedCustomerId,
        if (_selectedOrderId != null && _selectedOrderId!.isNotEmpty)
          'orderId': _selectedOrderId,
        'recordDate': _dispatchDate.toIso8601String().split('T')[0],
        'productType': _selectedProductType.apiValue,
        'packsSold': packs,
        'pricePerPack': price,
        'amountReceived': received,
        'paymentMethod': _selectedPaymentMethod.apiValue,
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      });

      ref.invalidate(salesDispatchesProvider);
      ref.invalidate(salesOrdersProvider);
      ref.invalidate(customersProvider);
      ref.invalidate(customerPaymentsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sales dispatch recorded successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record dispatch: $e'),
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
    final ordersAsync = ref.watch(salesOrdersProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.local_shipping, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          'Record Sales Dispatch',
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
                            child: Text('${c.name} (${c.customerType.label})', overflow: TextOverflow.ellipsis),
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

                  // Optional Order Link
                  ordersAsync.when(
                    data: (ordersData) {
                      final eligibleOrders = ordersData.items
                          .where((o) =>
                              o.status == OrderStatus.pending ||
                              o.status == OrderStatus.partiallyFulfilled)
                          .toList();

                      return DropdownButtonFormField<String?>(
                        value: _selectedOrderId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Linked Sales Order (Optional)',
                          prefixIcon: Icon(Icons.receipt_long),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Direct Dispatch (No Order)', overflow: TextOverflow.ellipsis),
                          ),
                          ...eligibleOrders.map((o) {
                            return DropdownMenuItem<String?>(
                              value: o.id,
                              child: Text(
                                '${o.orderNumber} - ${o.customerName ?? 'Customer'} (₹${o.totalAmount.toStringAsFixed(2)})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedOrderId = val;
                            if (val != null) {
                              final matched = eligibleOrders.firstWhere((o) => o.id == val);
                              _selectedCustomerId = matched.customerId;
                              if (matched.items.isNotEmpty) {
                                _selectedProductType = matched.items.first.productType;
                                final rem = matched.items.first.quantityOrdered - matched.items.first.quantityDispatched;
                                _packsSoldController.text = (rem > 0 ? rem : matched.items.first.quantityOrdered).toString();
                                _pricePerPackController.text = matched.items.first.unitPrice.toStringAsFixed(2);
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

                  // Date Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dispatchDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 7)),
                      );
                      if (picked != null) setState(() => _dispatchDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Dispatch Date *',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${_dispatchDate.year}-${_dispatchDate.month.toString().padLeft(2, '0')}-${_dispatchDate.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Product Type
                  DropdownButtonFormField<ProductType>(
                    value: _selectedProductType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Product Type *',
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    items: ProductType.values.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(p.label, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedProductType = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Quantity & Price
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _packsSoldController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Packs Sold *',
                            prefixIcon: Icon(Icons.format_list_numbered),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final parsed = int.tryParse(v);
                            if (parsed == null || parsed <= 0) return '> 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _pricePerPackController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Price / Pack (₹) *',
                            prefixIcon: Icon(Icons.currency_rupee),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final parsed = double.tryParse(v);
                            if (parsed == null || parsed <= 0) return '> 0';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Amount received & Payment method
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountReceivedController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Amount Collected (₹)',
                            prefixIcon: Icon(Icons.payments),
                            helperText: 'Immediate advance or full cash',
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v != null && v.isNotEmpty) {
                              final parsed = double.tryParse(v);
                              if (parsed == null || parsed < 0) return '>= 0';
                            }
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
                            labelText: 'Payment Method',
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

                  // Pricing Summary Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Dispatch Value:', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('₹${_computedTotalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Balance Due (A/R):', style: TextStyle(color: AppColors.textSecondary)),
                            Text('₹${_computedBalanceDue.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _computedBalanceDue > 0 ? AppColors.warning : AppColors.success,
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Dispatch Notes / Gate Pass Info',
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
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Post Dispatch'),
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
