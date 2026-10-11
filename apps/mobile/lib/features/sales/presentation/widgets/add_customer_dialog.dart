import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../sales_provider.dart';
import '../../domain/sales_models.dart';

class AddCustomerDialog extends ConsumerStatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  ConsumerState<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends ConsumerState<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _creditLimitController = TextEditingController(text: '0.00');

  CustomerType _selectedType = CustomerType.retail;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(salesRepositoryProvider);

      final creditLimit = double.tryParse(_creditLimitController.text.trim()) ?? 0.0;

      await repo.createCustomer({
        'name': _nameController.text.trim(),
        'customerType': _selectedType.apiValue,
        'creditLimit': creditLimit,
        if (_phoneController.text.trim().isNotEmpty)
          'phone': _phoneController.text.trim(),
        if (_emailController.text.trim().isNotEmpty)
          'email': _emailController.text.trim(),
        if (_addressController.text.trim().isNotEmpty)
          'address': _addressController.text.trim(),
      });

      ref.invalidate(customersProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer registered successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register customer: $e'),
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                        child: const Icon(Icons.person_add, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Text(
                        'Register Customer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Customer Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer / Shop Name *',
                      hintText: 'e.g. Modern Supermarket',
                      prefixIcon: Icon(Icons.store),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Customer name is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Customer Type Dropdown
                  DropdownButtonFormField<CustomerType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Customer Type *',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: CustomerType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Phone & Email
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Credit Limit
                  TextFormField(
                    controller: _creditLimitController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Credit Balance Limit (₹)',
                      prefixIcon: Icon(Icons.credit_card),
                      helperText: 'Maximum allowed outstanding balance',
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final parsed = double.tryParse(v);
                        if (parsed == null || parsed < 0) {
                          return 'Enter valid credit limit >= 0';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Address
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Delivery / Billing Address',
                      prefixIcon: Icon(Icons.location_on),
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
                            : const Text('Save Customer'),
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
