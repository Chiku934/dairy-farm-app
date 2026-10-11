import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/herd_models.dart';

class AnimalCard extends StatelessWidget {
  final AnimalModel animal;
  final VoidCallback onTap;

  const AnimalCard({
    super.key,
    required this.animal,
    required this.onTap,
  });

  Color _getStatusBgColor(AnimalStatus status) {
    switch (status) {
      case AnimalStatus.lactating:
        return const Color(0xFFDCFCE7);
      case AnimalStatus.dry:
        return const Color(0xFFF1F5F9);
      case AnimalStatus.pregnant:
        return const Color(0xFFE0E7FF);
      case AnimalStatus.heifer:
        return const Color(0xFFFEF3C7);
      case AnimalStatus.calf:
        return const Color(0xFFFEF9C3);
      case AnimalStatus.bull:
        return const Color(0xFFFCE7F3);
      case AnimalStatus.sold:
      case AnimalStatus.deceased:
        return const Color(0xFFFEE2E2);
    }
  }

  Color _getStatusTextColor(AnimalStatus status) {
    switch (status) {
      case AnimalStatus.lactating:
        return const Color(0xFF166534);
      case AnimalStatus.dry:
        return const Color(0xFF475569);
      case AnimalStatus.pregnant:
        return const Color(0xFF3730A3);
      case AnimalStatus.heifer:
        return const Color(0xFF92400E);
      case AnimalStatus.calf:
        return const Color(0xFF854D0E);
      case AnimalStatus.bull:
        return const Color(0xFF9D174D);
      case AnimalStatus.sold:
      case AnimalStatus.deceased:
        return const Color(0xFF991B1B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBg = _getStatusBgColor(animal.status);
    final statusColor = _getStatusTextColor(animal.status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: animal.isArchived ? AppColors.borderSubtle : AppColors.primary100,
          width: 1,
        ),
      ),
      color: animal.isArchived ? const Color(0xFFFAFAFA) : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: animal.isArchived ? Colors.grey.shade100 : AppColors.primary50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: animal.isArchived ? Colors.grey.shade300 : AppColors.primary200,
                  ),
                ),
                child: Icon(
                  animal.sex == AnimalSex.male ? Icons.male : Icons.pets,
                  color: animal.isArchived ? Colors.grey : AppColors.primary700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Bio Info
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          animal.earTag,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: animal.isArchived ? AppColors.textSecondary : AppColors.textMain,
                            decoration: animal.isArchived ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (animal.name != null && animal.name!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '· ${animal.name}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Breed: ${animal.breed.replaceAll('_', ' ')} · ${animal.ageString}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (animal.bodyWeightKg != null || animal.damTag != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (animal.bodyWeightKg != null)
                            Text(
                              '${animal.bodyWeightKg!.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          if (animal.bodyWeightKg != null && animal.damTag != null)
                            const Text(' · ', style: TextStyle(color: AppColors.textSecondary)),
                          if (animal.damTag != null)
                            Text(
                              'Dam: ${animal.damTag}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Status Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      animal.isArchived ? 'ARCHIVED' : animal.status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
