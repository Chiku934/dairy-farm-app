import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/licence_models.dart';
import '../licence_provider.dart';

class AddLicenceDialog extends ConsumerStatefulWidget {
  const AddLicenceDialog({super.key});

  @override
  ConsumerState<AddLicenceDialog> createState() => _AddLicenceDialogState();
}

class _AddLicenceDialogState extends ConsumerState<AddLicenceDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _authorityController = TextEditingController();
  final _holderController = TextEditingController();
  final _reminderDaysController = TextEditingController(text: '30');
  final _documentUrlController = TextEditingController();
  final _notesController = TextEditingController();

  LicenceType _selectedType = LicenceType.fssai;
  DateTime _issueDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _authorityController.dispose();
    _holderController.dispose();
    _reminderDaysController.dispose();
    _documentUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickIssueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _issueDate = picked);
    }
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: _issueDate.add(const Duration(days: 1)),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  String _formatDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_expiryDate.isBefore(_issueDate) || _expiryDate.isAtSameMomentAs(_issueDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expiry date must be strictly after issue date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = <String, dynamic>{
        'licenceName': _nameController.text.trim(),
        'licenceType': _selectedType.apiValue,
        'licenceNumber': _numberController.text.trim(),
        'issuingAuthority': _authorityController.text.trim(),
        'licenceHolder': _holderController.text.trim(),
        'issueDate': _formatDate(_issueDate),
        'expiryDate': _formatDate(_expiryDate),
        'reminderDaysBefore': int.tryParse(_reminderDaysController.text.trim()) ?? 30,
      };

      if (_documentUrlController.text.trim().isNotEmpty) {
        payload['documentUrl'] = _documentUrlController.text.trim();
      }
      if (_notesController.text.trim().isNotEmpty) {
        payload['notes'] = _notesController.text.trim();
      }

      await ref.read(licenceRepositoryProvider).createLicence(payload);
      ref.invalidate(licencesListProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Licence ${_numberController.text.trim()} registered successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save licence: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Register Regulatory Licence',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Licence Title *',
                          hintText: 'e.g. FSSAI Central Dairy License',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Licence title is required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<LicenceType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Compliance Category *',
                          border: OutlineInputBorder(),
                        ),
                        items: LicenceType.values.map((t) {
                          return DropdownMenuItem(value: t, child: Text(t.label));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedType = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _numberController,
                        decoration: const InputDecoration(
                          labelText: 'Licence Registration Number *',
                          hintText: 'e.g. 10020031000123',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Licence number is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _authorityController,
                        decoration: const InputDecoration(
                          labelText: 'Issuing Authority *',
                          hintText: 'e.g. FSSAI Eastern Region',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Issuing authority is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _holderController,
                        decoration: const InputDecoration(
                          labelText: 'Registered Entity / Holder *',
                          hintText: 'e.g. Green Pastures Organic Dairy Ltd',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Licence holder is required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickIssueDate,
                              icon: const Icon(Icons.date_range, size: 16),
                              label: Text('Issue: ${_formatDate(_issueDate)}'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickExpiryDate,
                              icon: const Icon(Icons.event_busy, size: 16),
                              label: Text('Expiry: ${_formatDate(_expiryDate)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _reminderDaysController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Reminder Lead Time (Days Before Expiry)',
                          hintText: '30',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Lead days required';
                          final num = int.tryParse(v.trim());
                          if (num == null || num < 1) return 'Must be 1 day or greater';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _documentUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Digital Certificate URL / Document Link',
                          hintText: 'https://...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Compliance Notes & Conditions',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Licence'),
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
