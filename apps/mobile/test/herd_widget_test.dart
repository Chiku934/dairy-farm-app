import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dairy_mobile/core/theme/app_theme.dart';
import 'package:dairy_mobile/features/herd/presentation/herd_screen.dart';
import 'package:dairy_mobile/features/herd/presentation/animal_detail_screen.dart';
import 'package:dairy_mobile/features/herd/presentation/herd_provider.dart';
import 'package:dairy_mobile/features/herd/domain/herd_models.dart';
import 'package:dairy_mobile/features/herd/domain/health_models.dart';
import 'package:dairy_mobile/features/herd/presentation/widgets/animal_card.dart';
import 'package:dairy_mobile/features/herd/presentation/widgets/reminders_banner.dart';
import 'package:dairy_mobile/features/herd/presentation/widgets/animal_form_modal.dart';

void main() {
  final sampleAnimals = [
    AnimalModel(
      id: 'c-01',
      earTag: 'TAG-101',
      name: 'Gauri',
      breed: 'HOLSTEIN_FRIESIAN',
      sex: AnimalSex.female,
      status: AnimalStatus.lactating,
      bodyWeightKg: 480.0,
      bodyConditionScore: 3.5,
      createdAt: DateTime.now(),
    ),
    AnimalModel(
      id: 'c-02',
      earTag: 'TAG-102',
      name: 'Kamadhenu',
      breed: 'JERSEY',
      sex: AnimalSex.female,
      status: AnimalStatus.lactating,
      bodyWeightKg: 420.0,
      bodyConditionScore: 3.5,
      createdAt: DateTime.now(),
    ),
    AnimalModel(
      id: 'c-05',
      earTag: 'TAG-105',
      name: 'Nandini',
      breed: 'HOLSTEIN_FRIESIAN',
      sex: AnimalSex.female,
      status: AnimalStatus.dry,
      bodyWeightKg: 510.0,
      createdAt: DateTime.now(),
    ),
    AnimalModel(
      id: 'c-06',
      earTag: 'TAG-106',
      name: 'Yamuna',
      breed: 'MURRAH',
      sex: AnimalSex.female,
      status: AnimalStatus.pregnant,
      bodyWeightKg: 550.0,
      createdAt: DateTime.now(),
    ),
  ];

  final sampleSummary = const HerdSummaryCountsModel(
    totalActive: 4,
    lactating: 2,
    dry: 1,
    pregnant: 1,
    heifer: 0,
    calf: 0,
    bull: 0,
    archived: 0,
  );

  final sampleWithdrawal = const ActiveWithdrawalModel(
    id: 'w-01',
    animalId: 'c-04',
    earTag: 'TAG-104',
    animalName: 'Surabhi',
    medicineVaccine: 'Ceftiofur Sodium Injection',
    prescribedDose: '10ml IM',
    withdrawalUntil: '2026-10-15',
    daysRemaining: 4,
  );

  final sampleTimeline = [
    const AnimalTimelineItemModel(
      id: 't-01',
      date: '2026-10-11',
      type: 'HEALTH',
      title: 'TREATMENT: Ceftiofur Sodium',
      subtitle: 'Diagnosis: Mastitis | Dose: 10ml IM',
      badge: 'Withdrawal: 2026-10-15',
    ),
    const AnimalTimelineItemModel(
      id: 't-02',
      date: '2026-10-10',
      type: 'MILKING',
      title: 'Milking: 14.5 L (MORNING)',
      subtitle: 'Disposition: ELIGIBLE',
      badge: '14.5 L',
    ),
    const AnimalTimelineItemModel(
      id: 't-03',
      date: '2026-01-15',
      type: 'BREEDING',
      title: 'Breeding: INSEMINATION',
      subtitle: 'Sire/Semen: SIRE-GIR-PRIME-09 · Exp. Calving: 2026-10-22',
      badge: 'Due: 2026-10-22',
    ),
  ];

  Widget createTestWidget({
    required Widget child,
    List<dynamic> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('Phase 6: Herd & Calves, Health & Breeding Widget Tests', () {
    testWidgets('HerdScreen renders search bar, status filter chips, and cattle cards', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            herdSummaryProvider.overrideWith((ref) => Future.value(sampleSummary)),
            animalsListProvider.overrideWith((ref) => Future.value(sampleAnimals)),
            activeWithdrawalsProvider.overrideWith((ref) => Future.value([])),
            healthRemindersProvider.overrideWith((ref) => Future.value([])),
            breedingRemindersProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const HerdScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Herd & Calves Registry'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Search bar
      expect(find.text('All Active (4)'), findsOneWidget);
      expect(find.text('Lactating (2)'), findsOneWidget);
      expect(find.text('Dry (1)'), findsOneWidget);
      expect(find.text('Pregnant (1)'), findsOneWidget);

      // Verify Animal Cards
      expect(find.text('TAG-101'), findsOneWidget);
      expect(find.text('· Gauri'), findsOneWidget);
      expect(find.text('TAG-102'), findsOneWidget);
      expect(find.text('TAG-105'), findsOneWidget);
      expect(find.text('TAG-106'), findsOneWidget);
    });

    testWidgets('RemindersBanner renders active milk safety withdrawal warning and days remaining', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: RemindersBanner(
              withdrawals: [sampleWithdrawal],
              healthReminders: const [],
              breedingReminders: const [],
              onAnimalSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1 Milk Withdrawal · 0 Reminders'), findsOneWidget);
      expect(find.text('Active Milk Safety Withdrawals'), findsNothing); // Collapsed initially

      // Expand tile
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.text('Active Milk Safety Withdrawals'), findsOneWidget);
      expect(find.text('TAG-104 (Surabhi)'), findsOneWidget);
      expect(find.text('4d left'), findsOneWidget);
    });

    testWidgets('AnimalDetailScreen displays Hero banner, biological metrics, and timeline items', (tester) async {
      final targetAnimal = sampleAnimals[0];

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            animalDetailProvider(targetAnimal.id).overrideWith((ref) => Future.value(targetAnimal)),
            animalHistoryProvider(targetAnimal.id).overrideWith((ref) => Future.value((animal: targetAnimal, timeline: sampleTimeline))),
            animalHealthRecordsProvider(targetAnimal.id).overrideWith((ref) => Future.value([])),
            animalBreedingRecordsProvider(targetAnimal.id).overrideWith((ref) => Future.value([])),
          ],
          child: AnimalDetailScreen(animalId: targetAnimal.id),
        ),
      );

      await tester.pumpAndSettle();

      // Hero banner
      expect(find.text('TAG-101 · Gauri'), findsOneWidget);
      expect(find.text('Physical & Vital Metrics'), findsOneWidget);
      expect(find.text('480.0 kg'), findsOneWidget);
      expect(find.text('3.5 / 5.0'), findsOneWidget);

      // Switch to Timeline tab
      await tester.tap(find.text('Timeline'));
      await tester.pumpAndSettle();

      expect(find.text('TREATMENT: Ceftiofur Sodium'), findsOneWidget);
      expect(find.text('Diagnosis: Mastitis | Dose: 10ml IM'), findsOneWidget);
      expect(find.text('Milking: 14.5 L (MORNING)'), findsOneWidget);
      expect(find.text('Breeding: INSEMINATION'), findsOneWidget);
    });

    testWidgets('AnimalFormModal validates required earTag field', (tester) async {
      bool saved = false;

      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: AnimalFormModal(
              onSave: (data) async {
                saved = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Register New Cattle'), findsOneWidget);

      // Tap Register Cattle with empty tag
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Ear tag required'), findsOneWidget);
      expect(saved, isFalse);

      // Enter valid ear tag
      await tester.enterText(find.byType(TextFormField).first, 'TAG-999');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(saved, isTrue);
    });

    testWidgets('AnimalCard shows archived label when animal is retired', (tester) async {
      final archivedAnimal = AnimalModel(
        id: 'c-archived',
        earTag: 'TAG-OLD-01',
        name: 'Ganga',
        breed: 'GIR',
        status: AnimalStatus.sold,
        isArchived: true,
        archiveReason: 'Sold to local farm',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: AnimalCard(
              animal: archivedAnimal,
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('TAG-OLD-01'), findsOneWidget);
      expect(find.text('ARCHIVED'), findsOneWidget);
    });
  });
}
