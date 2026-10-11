import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/herd_models.dart';

class ArchiveAnimalDialog extends StatefulWidget {
  final AnimalModel animal;
  final Future<void> Function({required String reason, AnimalStatus? status}) onConfirmArchive;

  const ArchiveAnimalDialog({
    super.key,
    required this.animal,
    required this.onConfirmArchive,
  });

  @override
  State<ArchiveAnimalDialog> createState() => _ArchiveAnimalDialogState();
}

class _ArchiveAnimalDialogState extends State<ArchiveAnimalDialog> {
  final _reasonController = TextEditingController();
  AnimalStatus _selectedStatus = AnimalStatus.sold;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Please state reason for archiving');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.onConfirmArchive(
        reason: reason,
        status: _selectedStatus,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.archive_outlined, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Archive Cattle: ${widget.animal.earTag}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Archiving removes this animal from active milking and herd tallies while permanently preserving all medical, breeding, and historical logs.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<AnimalStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Final Status'),
              items: const [
                DropdownMenuItem(value: AnimalStatus.sold, child: Text('Sold / Transferred')),
                DropdownMenuItem(value: AnimalStatus.deceased, child: Text('Deceased / Culled')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Archive Reason *',
                hintText: 'e.g. Sold to local dairy farmer at ₹45,000',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade800,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Confirm Archive'),
        ),
      ],
    );
  }
}
