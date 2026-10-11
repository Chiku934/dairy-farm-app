import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/health_models.dart';

class RecordHealthDialog extends StatefulWidget {
  final String animalId;
  final String animalTag;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const RecordHealthDialog({
    super.key,
    required this.animalId,
    required this.animalTag,
    required this.onSave,
  });

  @override
  State<RecordHealthDialog> createState() => _RecordHealthDialogState();
}

class _RecordHealthDialogState extends State<RecordHealthDialog> {
  final _formKey = GlobalKey<FormState>();

  CareType _careType = CareType.treatment;
  final _diagnosisController = TextEditingController();
  final _medicineController = TextEditingController();
  final _doseController = TextEditingController();
  final _vetController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _recordDate = DateTime.now();
  DateTime? _nextDueDate;
  DateTime? _withdrawalUntil;

  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _diagnosisController.dispose();
    _medicineController.dispose();
    _doseController.dispose();
    _vetController.dispose();
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
        'careType': _careType.apiValue,
        'medicineVaccine': _medicineController.text.trim(),
        'prescribedDose': _doseController.text.trim(),
      };

      if (_diagnosisController.text.trim().isNotEmpty) {
        payload['diagnosis'] = _diagnosisController.text.trim();
      }
      if (_vetController.text.trim().isNotEmpty) {
        payload['veterinarian'] = _vetController.text.trim();
      }
      if (_nextDueDate != null) {
        payload['nextDueDate'] = _nextDueDate!.toIso8601String().substring(0, 10);
      }
      if (_withdrawalUntil != null) {
        payload['withdrawalUntil'] = _withdrawalUntil!.toIso8601String().substring(0, 10);
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
                  const Icon(Icons.medical_services_outlined, color: AppColors.primary700),
                  const SizedBox(width: 8),
                  Text(
                    'Record Health Log: ${widget.animalTag}',
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
                      // Care Type & Date
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<CareType>(
                              value: _careType,
                              decoration: const InputDecoration(labelText: 'Care Type *'),
                              items: CareType.values
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _careType = val);
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
                                if (p != null) setState(() => _recordDate = p);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Distinct Veterinary Diagnosis
                      TextFormField(
                        controller: _diagnosisController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Veterinary Diagnosis (Distinct from Treatment)',
                          hintText: 'e.g. Clinical Mastitis in LF quarter, Tick Fever',
                          prefixIcon: Icon(Icons.biotech, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Medicine / Vaccine
                      TextFormField(
                        controller: _medicineController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Medicine / Vaccine Compound *',
                          hintText: 'e.g. Ceftiofur Sodium 10ml, FMD Booster',
                          prefixIcon: Icon(Icons.vaccines, size: 20),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Medicine/Vaccine required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Dose & Vet
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _doseController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Prescribed Dose *',
                                hintText: 'e.g. 10ml IM',
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Dose required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _vetController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Veterinarian',
                                hintText: 'Dr. B. K. Panda',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Milk Withdrawal Alert Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber),
                                SizedBox(width: 6),
                                Text(
                                  'Milk Safety Withdrawal Period',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'If this medication leaves residues, specify until when milk must be withheld from collection.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                side: BorderSide(color: Colors.amber.shade700),
                              ),
                              icon: const Icon(Icons.event_busy, size: 16, color: Colors.amber),
                              label: Text(
                                _withdrawalUntil == null
                                    ? 'Set Milk Withholding Date'
                                    : 'Withheld Until: ${_withdrawalUntil!.toIso8601String().substring(0, 10)}',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              onPressed: () async {
                                final p = await showDatePicker(
                                  context: context,
                                  initialDate: _withdrawalUntil ?? DateTime.now().add(const Duration(days: 3)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 90)),
                                );
                                if (p != null) setState(() => _withdrawalUntil = p);
                              },
                            ),
                            if (_withdrawalUntil != null)
                              TextButton(
                                onPressed: () => setState(() => _withdrawalUntil = null),
                                child: const Text('Clear withdrawal date', style: TextStyle(fontSize: 11)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Next Booster / Due Date
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.notification_add, size: 16),
                        label: Text(
                          _nextDueDate == null
                              ? 'Schedule Next Due / Booster Reminder'
                              : 'Booster Scheduled: ${_nextDueDate!.toIso8601String().substring(0, 10)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final p = await showDatePicker(
                            context: context,
                            initialDate: _nextDueDate ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (p != null) setState(() => _nextDueDate = p);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Clinical Notes',
                          hintText: 'Observations, response, administration route',
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
                            : const Text('Save Health Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
