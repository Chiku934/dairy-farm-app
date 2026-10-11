import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../sales_provider.dart';
import '../../domain/sales_models.dart';

class BookSalesOrderDialog extends ConsumerStatefulWidget {
  const BookSalesOrderDialog({super.key});

  @override
  ConsumerState<BookSalesOrderDialog> createState() => _BookSalesOrderDialogState();
}

class _OrderLineEntry {
  ProductType productType;
  double packSize;
  int quantity;
  double unitPrice;

  _OrderLineEntry({
    required this.productType,
    this.packSize = 1.0,
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => quantity * unitPrice;
}

class _BookSalesOrderDialogState extends ConsumerState<BookSalesOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _orderDate;
  late DateTime _deliveryDate;

  String? _selectedCustomerId;
  final _notesController = TextEditingController();

  final List<_OrderLineEntry> _lines = [
    _OrderLineEntry(productType: ProductType.milk, quantity: 50, unitPrice: 32.0),
  ];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _orderDate = DateTime.now();
    _deliveryDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _computedGrandTotal {
    return _lines.fold<double>(0.0, (sum, l) => sum + l.lineTotal);
  }

  void _addLine() {
    setState(() {
      _lines.add(_OrderLineEntry(productType: ProductType.paneer, quantity: 10, unitPrice: 160.0));
    });
  }

  void _removeLine(int idx) {
    if (_lines.length > 1) {
      setState(() => _lines.removeAt(idx));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(salesRepositoryProvider);

      await repo.createOrder({
        'customerId': _selectedCustomerId,
        'orderDate': _orderDate.toIso8601String().split('T')[0],
        'deliveryDate': _deliveryDate.toIso8601String().split('T')[0],
        'items': _lines.map((l) => {
          'productType': l.productType.apiValue,
          'packSize': l.packSize,
          'quantityOrdered': l.quantity,
          'unitPrice': l.unitPrice,
        }).toList(),
        if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
      });

      ref.invalidate(salesOrdersProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sales order booked successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book order: $e'),
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 760),
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
                        child: const Icon(Icons.assignment_outlined, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Book Sales Order', style: Theme.of(context).textTheme.titleLarge),
                            Text('Multi-line customer sales contract', style: Theme.of(context).textTheme.bodySmall),
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

                  // Customer Dropdown
                  customersAsync.when(
                    data: (customers) {
                      return DropdownButtonFormField<String>(
                        value: _selectedCustomerId,
                        decoration: const InputDecoration(
                          labelText: 'Customer *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: customers.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.name} (${c.customerType.label})'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCustomerId = val),
                        validator: (v) => v == null ? 'Customer is required' : null,
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Failed to load customers: $e'),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Order Date & Delivery Date Row
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _orderDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => _orderDate = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Order Date',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(_orderDate.toIso8601String().split('T')[0]),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _deliveryDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => _deliveryDate = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Delivery Target',
                              prefixIcon: Icon(Icons.local_shipping_outlined),
                            ),
                            child: Text(_deliveryDate.toIso8601String().split('T')[0]),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Line Items Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order Lines (${_lines.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Product'),
                        onPressed: _addLine,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Dynamic Order Lines List
                  ..._lines.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final line = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<ProductType>(
                                  value: line.productType,
                                  isDense: true,
                                  decoration: const InputDecoration(labelText: 'Product'),
                                  items: ProductType.values.map((p) {
                                    return DropdownMenuItem(value: p, child: Text(p.label, overflow: TextOverflow.ellipsis));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => line.productType = val);
                                  },
                                ),
                              ),
                              if (_lines.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                  onPressed: () => _removeLine(idx),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: line.quantity.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Packs *', isDense: true),
                                  onChanged: (v) {
                                    setState(() {
                                      line.quantity = int.tryParse(v) ?? 0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: line.unitPrice.toString(),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Price (₹) *', isDense: true),
                                  onChanged: (v) {
                                    setState(() {
                                      line.unitPrice = double.tryParse(v) ?? 0.0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₹${line.lineTotal.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),

                  // Grand Total Preview Box
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Order Value:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '₹${_computedGrandTotal.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Actions
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
                        label: Text(_isSubmitting ? 'Booking...' : 'Book Order'),
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
