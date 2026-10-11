import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/breeding_models.dart';

class RecordBreedingDialog extends StatefulWidget {
  final String animalId;
  final String animalTag;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const RecordBreedingDialog({
    super.key,
    required this.animalId,
    required this.animalTag,
    required this.onSave,
  });

  @override
  State<RecordBreedingDialog> createState() => _RecordBreedingDialogState();
}

class _RecordBreedingDialogState extends State<RecordBreedingDialog> {
  final _formKey = GlobalKey<FormState>();

  BreedingEventType _eventType = BreedingEventType.insemination;
  final _sireController = TextEditingController();
  final _calfTagController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _recordDate = DateTime.now();
  DateTime? _expectedCalvingDate;
  DateTime? _nextCheckDate;

  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _recalculateDates();
  }

  void _recalculateDates() {
    if (_eventType == BreedingEventType.insemination) {
      _expectedCalvingDate = _recordDate.add(const Duration(days: 280));
      _nextCheckDate = _recordDate.add(const Duration(days: 45));
    } else if (_eventType == BreedingEventType.heat) {
      _expectedCalvingDate = null;
      _nextCheckDate = _recordDate.add(const Duration(days: 21));
    } else {
      _nextCheckDate = null;
    }
  }

  @override
  void dispose() {
    _sireController.dispose();
    _calfTagController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final payload = <String, dynamic>{
        'animalId': widget.animalId,
        'recordDate': _recordDate.toIso8601String().substring(0, 10),
        'eventType': _eventType.apiValue,
      };

      if (_sireController.text.trim().isNotEmpty) {
        payload['sireSemenId'] = _sireController.text.trim();
      }
      if (_calfTagController.text.trim().isNotEmpty) {
        payload['calfTag'] = _calfTagController.text.trim().toUpperCase();
      }
      if (_expectedCalvingDate != null) {
        payload['expectedCalvingDate'] = _expectedCalvingDate!.toIso8601String().substring(0, 10);
      }
      if (_nextCheckDate != null) {
        payload['nextCheckDate'] = _nextCheckDate!.toIso8601String().substring(0, 10);
      }
      if (_notesController.text.trim().isNotEmpty) {
        payload['notes'] = _notesController.text.trim();
      }

      await widget.onSave(payload);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.favorite_outline, color: AppColors.primary700),
                  const SizedBox(width: 8),
                  Text(
                    'Record Breeding Event: ${widget.animalTag}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                        const SizedBox(height: 14),
                      ],
                      // Event Type & Date
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<BreedingEventType>(
                              value: _eventType,
                              decoration: const InputDecoration(labelText: 'Event Type *'),
                              items: BreedingEventType.values
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _eventType = val;
                                    _recalculateDates();
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                _recordDate.toIso8601String().substring(0, 10),
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () async {
                                final p = await showDatePicker(
                                  context: context,
                                  initialDate: _recordDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (p != null) {
                                  setState(() {
                                    _recordDate = p;
                                    _recalculateDates();
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Sire ID (for Insemination)
                      if (_eventType == BreedingEventType.insemination ||
                          _eventType == BreedingEventType.pregnancyConfirmed) ...[
                        TextFormField(
                          controller: _sireController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Sire Identifier / Semen Straw Lot',
                            hintText: 'e.g. SIRE-GIR-PRIME-09',
                            prefixIcon: Icon(Icons.badge_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Calf Tag (for Calving)
                      if (_eventType == BreedingEventType.calving) ...[
                        TextFormField(
                          controller: _calfTagController,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Newborn Calf Tag',
                            hintText: 'e.g. TAG-111',
                            prefixIcon: Icon(Icons.child_care, size: 20),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Insemination Gestation Helper Box
                      if (_eventType == BreedingEventType.insemination) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.calculate_outlined, size: 18, color: AppColors.primary700),
                                  SizedBox(width: 6),
                                  Text(
                                    'Standard ~280-Day Gestation Alert',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary900),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Expected Calving: ${_expectedCalvingDate?.toIso8601String().substring(0, 10) ?? "--"} (~280 days)\nPregnancy Check: ${_nextCheckDate?.toIso8601String().substring(0, 10) ?? "--"} (~45 days)',
                                style: const TextStyle(fontSize: 12, color: AppColors.primary800),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Next check / Calving dates override
                      Row(
                        children: [
                          if (_eventType == BreedingEventType.insemination ||
                              _eventType == BreedingEventType.pregnancyConfirmed)
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.event, size: 16),
                                label: Text(
                                  _expectedCalvingDate == null
                                      ? 'Set Calving Date'
                                      : 'Calving: ${_expectedCalvingDate!.toIso8601String().substring(0, 10)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onPressed: () async {
                                  final p = await showDatePicker(
                                    context: context,
                                    initialDate: _expectedCalvingDate ?? DateTime.now().add(const Duration(days: 280)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 350)),
                                  );
                                  if (p != null) setState(() => _expectedCalvingDate = p);
                                },
                              ),
                            ),
                          if (_eventType == BreedingEventType.insemination ||
                              _eventType == BreedingEventType.heat ||
                              _eventType == BreedingEventType.pregnancyCheck) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.check_circle_outline, size: 16),
                                label: Text(
                                  _nextCheckDate == null
                                      ? 'Next Check Date'
                                      : 'Check: ${_nextCheckDate!.toIso8601String().substring(0, 10)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onPressed: () async {
                                  final p = await showDatePicker(
                                    context: context,
                                    initialDate: _nextCheckDate ?? DateTime.now().add(const Duration(days: 45)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 120)),
                                  );
                                  if (p != null) setState(() => _nextCheckDate = p);
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Technician & Event Notes',
                          hintText: 'Insemination details, ultrasound notes, calf health',
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Breeding Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
