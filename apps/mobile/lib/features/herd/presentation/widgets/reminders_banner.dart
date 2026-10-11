import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/health_models.dart';
import '../../domain/breeding_models.dart';

class RemindersBanner extends StatelessWidget {
  final List<ActiveWithdrawalModel> withdrawals;
  final List<HealthReminderModel> healthReminders;
  final List<BreedingReminderModel> breedingReminders;
  final ValueChanged<String> onAnimalSelected;

  const RemindersBanner({
    super.key,
    required this.withdrawals,
    required this.healthReminders,
    required this.breedingReminders,
    required this.onAnimalSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (withdrawals.isEmpty && healthReminders.isEmpty && breedingReminders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: withdrawals.isNotEmpty ? Colors.amber.shade400 : AppColors.primary200,
          width: 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Icon(
          withdrawals.isNotEmpty ? Icons.warning_amber_rounded : Icons.notifications_active_outlined,
          color: withdrawals.isNotEmpty ? Colors.amber.shade800 : AppColors.primary700,
        ),
        title: Text(
          withdrawals.isNotEmpty
              ? '${withdrawals.length} Milk Withdrawal · ${healthReminders.length + breedingReminders.length} Reminders'
              : '${healthReminders.length + breedingReminders.length} Scheduled Reminders Due',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: withdrawals.isNotEmpty ? Colors.amber.shade900 : AppColors.primary900,
          ),
        ),
        subtitle: Text(
          withdrawals.isNotEmpty
              ? 'Milk withheld for safety. Tap to view active withdrawals & boosters.'
              : 'Upcoming vaccinations & calving alerts.',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        children: [
          // Active Withdrawals
          if (withdrawals.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.event_busy, size: 16, color: Colors.amber),
                SizedBox(width: 6),
                Text(
                  'Active Milk Safety Withdrawals',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...withdrawals.map((w) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9C3).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${w.earTag}${w.animalName != null ? ' (' + w.animalName! + ')' : ''}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Rx: ${w.medicineVaccine} · Withheld until ${w.withdrawalUntil}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${w.daysRemaining}d left',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 10),
          ],

          // Health Boosters
          if (healthReminders.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.vaccines_outlined, size: 16, color: AppColors.primary700),
                SizedBox(width: 6),
                Text(
                  'Vaccination & Deworming Boosters Due',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary800),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...healthReminders.map((h) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${h.earTag} · ${h.careType.label}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              '${h.medicineVaccine} · Due: ${h.nextDueDate}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: h.isOverdue ? Colors.red.shade100 : AppColors.primary100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          h.isOverdue ? 'Overdue!' : 'in ${h.daysRemaining}d',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: h.isOverdue ? Colors.red.shade800 : AppColors.primary800,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 10),
          ],

          // Breeding Reminders
          if (breedingReminders.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.child_care, size: 16, color: Colors.purple),
                SizedBox(width: 6),
                Text(
                  'Upcoming Calvings & Pregnancy Checks',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...breedingReminders.map((b) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${b.earTag} · ${b.isCalving ? "Expected Calving" : "Pregnancy Check"}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Date: ${b.targetDate}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'in ${b.daysRemaining}d',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.purple.shade900),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
