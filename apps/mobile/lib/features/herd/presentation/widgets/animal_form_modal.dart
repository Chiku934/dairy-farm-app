import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/herd_models.dart';

class AnimalFormModal extends StatefulWidget {
  final AnimalModel? initialAnimal;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const AnimalFormModal({
    super.key,
    this.initialAnimal,
    required this.onSave,
  });

  @override
  State<AnimalFormModal> createState() => _AnimalFormModalState();
}

class _AnimalFormModalState extends State<AnimalFormModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _earTagController;
  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _weightController;
  late TextEditingController _damTagController;
  late TextEditingController _bcsController;
  late TextEditingController _notesController;

  late AnimalSex _selectedSex;
  late AnimalStatus _selectedStatus;
  DateTime? _dateOfBirth;
  DateTime? _lastCalvingDate;

  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _commonBreeds = [
    'GIR',
    'SAHIWAL',
    'HOLSTEIN_FRIESIAN',
    'JERSEY',
    'MURRAH',
    'RED_SINDHI',
    'KANKREJ',
    'CROSSBREED',
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.initialAnimal;
    _earTagController = TextEditingController(text: a?.earTag ?? '');
    _nameController = TextEditingController(text: a?.name ?? '');
    _breedController = TextEditingController(text: a?.breed ?? 'GIR');
    _weightController = TextEditingController(text: a?.bodyWeightKg?.toString() ?? '');
    _damTagController = TextEditingController(text: a?.damTag ?? '');
    _bcsController = TextEditingController(text: a?.bodyConditionScore?.toString() ?? '');
    _notesController = TextEditingController(text: a?.notes ?? '');

    _selectedSex = a?.sex ?? AnimalSex.female;
    _selectedStatus = a?.status ?? AnimalStatus.lactating;
    if (a?.dateOfBirth != null) {
      _dateOfBirth = DateTime.tryParse(a!.dateOfBirth!);
    }
    if (a?.lastCalvingDate != null) {
      _lastCalvingDate = DateTime.tryParse(a!.lastCalvingDate!);
    }
  }

  @override
  void dispose() {
    _earTagController.dispose();
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _damTagController.dispose();
    _bcsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final payload = <String, dynamic>{
        'earTag': _earTagController.text.trim().toUpperCase(),
        'name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        'breed': _breedController.text.trim().toUpperCase(),
        'sex': _selectedSex.apiValue,
        'status': _selectedStatus.apiValue,
      };

      if (_weightController.text.trim().isNotEmpty) {
        payload['bodyWeightKg'] = double.tryParse(_weightController.text.trim());
      }
      if (_damTagController.text.trim().isNotEmpty) {
        payload['damTag'] = _damTagController.text.trim().toUpperCase();
      }
      if (_bcsController.text.trim().isNotEmpty) {
        payload['bodyConditionScore'] = double.tryParse(_bcsController.text.trim());
      }
      if (_notesController.text.trim().isNotEmpty) {
        payload['notes'] = _notesController.text.trim();
      }
      if (_dateOfBirth != null) {
        payload['dateOfBirth'] = _dateOfBirth!.toIso8601String().substring(0, 10);
      }
      if (_lastCalvingDate != null) {
        payload['lastCalvingDate'] = _lastCalvingDate!.toIso8601String().substring(0, 10);
      }

      await widget.onSave(payload);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialAnimal != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add_circle,
                    color: AppColors.primary700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Edit Animal: ${widget.initialAnimal!.earTag}' : 'Register New Cattle',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Ear Tag & Name
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _earTagController,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Ear Tag / ID *',
                                hintText: 'e.g. TAG-110',
                                prefixIcon: Icon(Icons.tag, size: 20),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Ear tag required';
                                if (val.trim().length < 2) return 'Min 2 characters';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Name / Nickname',
                                hintText: 'e.g. Ganga',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Breed & Sex
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: DropdownButtonFormField<String>(
                              value: _commonBreeds.contains(_breedController.text)
                                  ? _breedController.text
                                  : 'GIR',
                              decoration: const InputDecoration(
                                labelText: 'Breed *',
                                prefixIcon: Icon(Icons.category, size: 20),
                              ),
                              items: _commonBreeds
                                  .map((b) => DropdownMenuItem(
                                        value: b,
                                        child: Text(b.replaceAll('_', ' ')),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) _breedController.text = val;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<AnimalSex>(
                              value: _selectedSex,
                              decoration: const InputDecoration(labelText: 'Sex *'),
                              items: AnimalSex.values
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s.label),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedSex = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Lifecycle Status
                      DropdownButtonFormField<AnimalStatus>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Lifecycle Stage *',
                          prefixIcon: Icon(Icons.timeline, size: 20),
                        ),
                        items: AnimalStatus.values
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.label),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStatus = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Weight & BCS
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Body Weight (kg)',
                                hintText: '450.0',
                                suffixText: 'kg',
                              ),
                              validator: (val) {
                                if (val != null && val.trim().isNotEmpty) {
                                  final num = double.tryParse(val.trim());
                                  if (num == null || num <= 0 || num > 1500) {
                                    return 'Invalid weight';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _bcsController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Condition (1-5)',
                                hintText: '3.5',
                              ),
                              validator: (val) {
                                if (val != null && val.trim().isNotEmpty) {
                                  final num = double.tryParse(val.trim());
                                  if (num == null || num < 1.0 || num > 5.0) {
                                    return 'Range: 1.0 - 5.0';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Dam Tag Reference
                      TextFormField(
                        controller: _damTagController,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Dam (Mother) Tag',
                          hintText: 'e.g. TAG-101',
                          prefixIcon: Icon(Icons.family_restroom, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dates (DOB & Calving)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: AppColors.borderSubtle),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.cake, size: 18),
                              label: Text(
                                _dateOfBirth == null
                                    ? 'Select DOB'
                                    : 'DOB: ${_dateOfBirth!.toIso8601String().substring(0, 10)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dateOfBirth ?? DateTime.now(),
                                  firstDate: DateTime(2010),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) setState(() => _dateOfBirth = picked);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: AppColors.borderSubtle),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.event, size: 18),
                              label: Text(
                                _lastCalvingDate == null
                                    ? 'Last Calving'
                                    : 'Calved: ${_lastCalvingDate!.toIso8601String().substring(0, 10)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _lastCalvingDate ?? DateTime.now(),
                                  firstDate: DateTime(2015),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) setState(() => _lastCalvingDate = picked);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes & Markings',
                          hintText: 'Color markings, lineage notes, dietary requirements',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save button
                      ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                isEditing ? 'Save Changes' : 'Register Cattle',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
