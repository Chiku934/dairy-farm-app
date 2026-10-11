import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../inventory_provider.dart';
import '../../domain/inventory_models.dart';

class AddSupplierDialog extends ConsumerStatefulWidget {
  const AddSupplierDialog({super.key});

  @override
  ConsumerState<AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends ConsumerState<AddSupplierDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  SupplierCategory _selectedCategory = SupplierCategory.feed;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);

      await repo.createSupplier({
        'name': _nameController.text.trim(),
        'category': _selectedCategory.apiValue,
        if (_contactPersonController.text.trim().isNotEmpty)
          'contactPerson': _contactPersonController.text.trim(),
        if (_phoneController.text.trim().isNotEmpty)
          'phone': _phoneController.text.trim(),
        if (_emailController.text.trim().isNotEmpty)
          'email': _emailController.text.trim(),
        if (_addressController.text.trim().isNotEmpty)
          'address': _addressController.text.trim(),
      });

      ref.invalidate(suppliersProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supplier registered successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register supplier: $e'),
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
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.business_outlined, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Register Supplier', style: Theme.of(context).textTheme.titleLarge),
                            Text('Add vendor for procurement tracking', style: Theme.of(context).textTheme.bodySmall),
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

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Vendor / Company Name *',
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Company name is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  DropdownButtonFormField<SupplierCategory>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Supply Category *',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: SupplierCategory.values.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c.label));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    controller: _contactPersonController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Person',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone_outlined),
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
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
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
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check),
                        label: Text(_isSubmitting ? 'Saving...' : 'Add Supplier'),
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
