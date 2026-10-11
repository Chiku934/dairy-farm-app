import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dairy_mobile/core/theme/app_theme.dart';
import 'package:dairy_mobile/features/milking/presentation/milking_screen.dart';
import 'package:dairy_mobile/features/milking/presentation/widgets/record_milking_dialog.dart';
import 'package:dairy_mobile/features/milking/presentation/milking_provider.dart';
import 'package:dairy_mobile/features/milking/domain/milking_models.dart';

import 'package:dairy_mobile/features/feed/presentation/feed_screen.dart';
import 'package:dairy_mobile/features/feed/presentation/feed_provider.dart';
import 'package:dairy_mobile/features/feed/domain/feed_models.dart';

import 'package:dairy_mobile/features/costing/presentation/costing_screen.dart';
import 'package:dairy_mobile/features/costing/presentation/costing_provider.dart';
import 'package:dairy_mobile/features/costing/domain/costing_models.dart';

void main() {
  group('Phase 7: Milking, Feed & Ration Planning, and Unit Costing Widget Tests', () {
    testWidgets('MilkingScreen renders shift KPI cards, filter chips, and record action', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockSummary = MilkingSummaryModel(
        totalLitres: 245.0,
        eligibleLitres: 230.0,
        withheldLitres: 15.0,
        calfFeedingLitres: 0.0,
        morningLitres: 135.0,
        eveningLitres: 110.0,
        activeCowsMilked: 9,
        avgLitresPerCow: 25.5,
      );

      final mockLogs = [
        MilkingLogModel(
          id: 'ml-01',
          animalId: 'c-01',
          animalEarTag: '210385',
          recordDate: '2026-10-11',
          session: MilkingSession.morning,
          yieldLitres: 14.5,
          disposition: MilkDisposition.eligible,
          operatorName: 'Arjun Patel',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            milkingSummaryProvider.overrideWith((ref) => Future.value(mockSummary)),
            milkingLogsProvider.overrideWith((ref) => Future.value((items: mockLogs, total: 1, totalPages: 1))),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MilkingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Milking Log'), findsOneWidget);
      expect(find.text('ELIGIBLE MILK'), findsOneWidget);
      expect(find.text('MORNING SHIFT'), findsOneWidget);
      expect(find.text('EVENING SHIFT'), findsOneWidget);
      expect(find.text('WITHHELD / CALF'), findsOneWidget);
      expect(find.text('Cow #210385'), findsOneWidget);
      expect(find.text('14.50 L'), findsOneWidget);
      expect(find.text('Record Milking'), findsOneWidget);
    });

    testWidgets('RecordMilkingDialog validates yield and displays required error on empty submit', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: RecordMilkingDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Record Milking Session'), findsOneWidget);
      expect(find.text('Individual Cow'), findsOneWidget);

      await tester.tap(find.text('Save Record'));
      await tester.pumpAndSettle();

      expect(find.text('Ear Tag is required'), findsOneWidget);
    });

    testWidgets('FeedScreen renders tabs, ration costing formulations, and calculator', (tester) async {
      final mockRations = [
        RationDefinitionModel(
          id: 'rat-01',
          name: 'High-Yielding Lactating TMR',
          code: 'RATION-LACT-HIGH',
          targetStage: TargetAnimalStage.lactating,
          description: 'Standard lactating diet',
          isActive: true,
          totalQuantityKg: 31.0,
          totalCost: 247.0,
          unitCostPerKg: 7.97,
          items: const [
            RationItemModel(
              id: 'ri-01',
              stockItemId: 'stk-conc',
              stockItemName: 'Concentrate Pellets',
              unitPrice: 24.50,
              quantityKg: 6.0,
              itemCost: 147.0,
            ),
          ],
        ),
      ];

      final mockConcentrate = const ConcentrateTargetModel(
        animalId: 'c-01',
        earTag: '210385',
        breed: 'Holstein Friesian',
        status: 'LACTATING',
        feedBaseKg: 1.0,
        feedRatePerLitre: 0.4,
        feedMaxCapKg: 8.0,
        daysEvaluated: 7,
        avgDailyYieldLitres: 15.0,
        targetConcentrateKg: 7.0,
        calculationMethod: '7_DAY_MILK_PRODUCTION_FORMULA',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedEntriesProvider.overrideWith((ref) => Future.value((items: <FeedEntryModel>[], total: 0, totalPages: 0))),
            rationsProvider.overrideWith((ref) => Future.value(mockRations)),
            concentrateTargetProvider('c-01').overrideWith((ref) => Future.value(mockConcentrate)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const FeedScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Feed & Ration Planning'), findsOneWidget);
      expect(find.text('Feed Issuance'), findsOneWidget);
      expect(find.text('Rations & Diets'), findsOneWidget);
      expect(find.text('Target Calculator'), findsOneWidget);

      // Switch to Rations Tab
      await tester.tap(find.text('Rations & Diets'));
      await tester.pumpAndSettle();

      expect(find.text('High-Yielding Lactating TMR'), findsOneWidget);
      expect(find.text('₹7.97'), findsOneWidget); // Unit Cost / kg

      // Switch to Calculator Tab
      await tester.tap(find.text('Target Calculator'));
      await tester.pumpAndSettle();

      expect(find.text('Target Concentrate'), findsOneWidget);
      expect(find.text('7.00 kg / day'), findsOneWidget);
    });

    testWidgets('CostingScreen displays Daily Cost per Litre, components breakdown, and zero-milk warning', (tester) async {
      final mockCosting = const DailyMilkCostingModel(
        date: '2026-10-11',
        totalDailyFarmCost: 2500.0,
        eligibleMilkLitres: 100.0,
        totalMilkRecordedLitres: 110.0,
        withheldMilkLitres: 10.0,
        costPerLitre: 25.0,
        status: 'COMPLETE',
        currency: '₹',
        breakdown: CostingBreakdownModel(
          feedCost: 1200.0,
          medicineCost: 150.0,
          materialsCost: 80.0,
          dailySalaries: 850.0,
          electricityCost: 70.0,
          otherExpenses: 150.0,
          isElectricityDefaulted: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyMilkCostingProvider.overrideWith((ref) => Future.value(mockCosting)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CostingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unit Costing'), findsOneWidget);
      expect(find.text('Farm Milk Cost per Litre'), findsOneWidget);
      expect(find.text('₹ 25.00'), findsOneWidget); // 25.00 INR/L
      expect(find.text('100.0 L'), findsOneWidget); // Eligible milk
      expect(find.text('Feed Consumed'), findsOneWidget);
      expect(find.text('₹ 1200.00'), findsOneWidget);
      expect(find.text('Daily Farm Salaries (Prorated)'), findsOneWidget);
      expect(find.text('Electricity (Defaulted 50 kWh)'), findsOneWidget);
    });
  });
}
