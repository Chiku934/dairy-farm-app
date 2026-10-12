import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/settings_models.dart';
import '../settings_provider.dart';

class EditSettingsDialog extends ConsumerStatefulWidget {
  final FarmSettingsModel currentSettings;

  const EditSettingsDialog({super.key, required this.currentSettings});

  @override
  ConsumerState<EditSettingsDialog> createState() => _EditSettingsDialogState();
}

class _EditSettingsDialogState extends ConsumerState<EditSettingsDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _districtController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _bmcController;
  late TextEditingController _tariffController;
  late TextEditingController _feedBaseController;
  late TextEditingController _feedRateController;
  late TextEditingController _feedCapController;
  late TextEditingController _mgmtPctController;
  late TextEditingController _operatorController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final s = widget.currentSettings;
    _nameController = TextEditingController(text: s.farmName);
    _phoneController = TextEditingController(text: s.contactPhone);
    _emailController = TextEditingController(text: s.contactEmail);
    _districtController = TextEditingController(text: s.district);
    _stateController = TextEditingController(text: s.state);
    _pincodeController = TextEditingController(text: s.pincode);
    _bmcController = TextEditingController(text: s.bmcCapacityLitres.toString());
    _tariffController = TextEditingController(text: s.electricityTariff.toString());
    _feedBaseController = TextEditingController(text: s.feedBaseKg.toString());
    _feedRateController = TextEditingController(text: s.feedRatePerLitre.toString());
    _feedCapController = TextEditingController(text: s.feedMaxCapKg.toString());
    _mgmtPctController = TextEditingController(text: s.mgmtSalaryToFarmPct.toString());
    _operatorController = TextEditingController(text: s.operatorName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _bmcController.dispose();
    _tariffController.dispose();
    _feedBaseController.dispose();
    _feedRateController.dispose();
    _feedCapController.dispose();
    _mgmtPctController.dispose();
    _operatorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final payload = <String, dynamic>{
        'farmName': _nameController.text.trim(),
        'contactPhone': _phoneController.text.trim(),
        'contactEmail': _emailController.text.trim(),
        'district': _districtController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'bmcCapacityLitres': double.parse(_bmcController.text.trim()),
        'electricityTariff': double.parse(_tariffController.text.trim()),
        'feedBaseKg': double.parse(_feedBaseController.text.trim()),
        'feedRatePerLitre': double.parse(_feedRateController.text.trim()),
        'feedMaxCapKg': double.parse(_feedCapController.text.trim()),
        'mgmtSalaryToFarmPct': double.parse(_mgmtPctController.text.trim()),
        'operatorName': _operatorController.text.trim(),
      };

      await ref.read(settingsRepositoryProvider).updateSettings(payload);
      ref.invalidate(farmSettingsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Farm operational parameters updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update settings: $e'), backgroundColor: Colors.red),
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
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Edit Farm Operating Parameters',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
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
                      const Text(
                        'FARM IDENTITY & CONTACT',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Enterprise Name *', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(labelText: 'Contact Phone', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(labelText: 'Contact Email', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _districtController,
                              decoration: const InputDecoration(labelText: 'District', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _stateController,
                              decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _pincodeController,
                              decoration: const InputDecoration(labelText: 'Pincode', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'RATIONS, STORAGE & TARIFFS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _bmcController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'BMC Capacity (L) *', border: OutlineInputBorder()),
                              validator: (v) {
                                final n = double.tryParse(v ?? '');
                                if (n == null || n < 100) return 'Min 100 L';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _tariffController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Power Tariff (₹/unit) *', border: OutlineInputBorder()),
                              validator: (v) {
                                final n = double.tryParse(v ?? '');
                                if (n == null || n < 0) return 'Invalid rate';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _feedBaseController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Base Feed (kg/day)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _feedRateController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Feed/Litre (kg/L)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _feedCapController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Feed Max Cap (kg)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _mgmtPctController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Mgmt Salary to Farm (%)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _operatorController,
                              decoration: const InputDecoration(labelText: 'Default Operator Name', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
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
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save Parameters'),
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
