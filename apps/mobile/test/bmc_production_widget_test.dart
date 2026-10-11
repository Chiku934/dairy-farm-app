import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dairy_mobile/core/theme/app_theme.dart';
import 'package:dairy_mobile/features/bmc/presentation/bmc_screen.dart';
import 'package:dairy_mobile/features/bmc/presentation/widgets/record_intake_dialog.dart';
import 'package:dairy_mobile/features/bmc/presentation/bmc_provider.dart';
import 'package:dairy_mobile/features/bmc/domain/bmc_models.dart';

import 'package:dairy_mobile/features/production/presentation/production_screen.dart';
import 'package:dairy_mobile/features/production/presentation/batch_detail_screen.dart';
import 'package:dairy_mobile/features/production/presentation/widgets/create_batch_dialog.dart';
import 'package:dairy_mobile/features/production/presentation/production_provider.dart';
import 'package:dairy_mobile/features/production/domain/production_models.dart';

void main() {
  group('Phase 8: BMC Milk Intake and Production Batches Widget Tests', () {
    testWidgets('BmcScreen renders tank capacity gauge, live balance metric, and intake logs', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const mockBalance = BmcTankBalanceModel(
        capacityLitres: 2000.0,
        currentBalanceLitres: 1500.0,
        availableCapacityLitres: 500.0,
        utilizationPercentage: 75.0,
        status: 'WARNING',
        totalAcceptedIntake: 2200.0,
        totalProductionConsumed: 690.0,
        totalWastageLost: 10.0,
        todayFarmAccepted: 150.0,
        todayExternalAccepted: 0.0,
        todayRejected: 0.0,
      );

      final mockIntakes = [
        BmcIntakeLogModel(
          id: 'int-01',
          batchNumber: 'INT-FRM-20261018-AM-101',
          recordDate: '2026-10-18',
          shift: IntakeShift.am,
          source: MilkIntakeSource.farm,
          supplierRoute: 'Parlour A',
          quantityLitres: 150.0,
          externalTotalCost: 0.0,
          decision: IntakeDecision.accepted,
          temperatureC: 4.2,
          fatPercentage: 4.15,
          snfPercentage: 8.65,
          clr: 29.0,
          ph: 6.68,
          operatorName: 'Ramesh Patel',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bmcTankBalanceProvider.overrideWith((ref) => Future.value(mockBalance)),
            bmcIntakeListProvider.overrideWith((ref) => Future.value((items: mockIntakes, total: 1, totalPages: 1))),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const BmcScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('BMC & Milk Intake'), findsOneWidget);
      expect(find.text('1500.0 L'), findsOneWidget);
      expect(find.text('75.0% Full'), findsOneWidget);
      expect(find.text('Total Accepted'), findsOneWidget);
      expect(find.text('INT-FRM-20261018-AM-101'), findsOneWidget);
      expect(find.text('Record Intake'), findsOneWidget);
    });

    testWidgets('RecordIntakeDialog validates quantity on empty submit', (tester) async {
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
              body: RecordIntakeDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Record Milk Intake'), findsOneWidget);
      expect(find.text('Internal Farm'), findsOneWidget);

      await tester.tap(find.text('Save Intake'));
      await tester.pumpAndSettle();

      expect(find.text('Quantity is required'), findsOneWidget);
    });

    testWidgets('ProductionScreen renders batch cards with conversion yield metrics', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockBatches = [
        ProductionBatchModel(
          id: 'pb-01',
          batchNumber: 'BATCH-PAN-20261018-001',
          recordDate: '2026-10-18',
          shift: 'AM',
          productType: ProductType.paneer,
          status: BatchStatus.completed,
          bmcMilkConsumedL: 100.0,
          finishedQuantity: 18.0,
          yieldPercentage: 18.0,
          unitOfMeasure: 'KG',
          lpgUsedKg: 2.0,
          byproductQuantityKg: 80.0,
          expiryDate: '2026-10-25',
          qualityRelease: QualityReleaseStatus.approved,
          operatorName: 'Suresh Kumar',
          createdAt: DateTime.now(),
          linkedIntakesCount: 1,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productionBatchesProvider.overrideWith((ref) => Future.value((items: mockBatches, total: 1, totalPages: 1))),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProductionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Production Batches'), findsOneWidget);
      expect(find.text('BATCH-PAN-20261018-001'), findsOneWidget);
      expect(find.text('18.0 KG'), findsOneWidget);
      expect(find.text('100.0 L'), findsOneWidget);
      expect(find.text('18.0%'), findsOneWidget);
      expect(find.text('Approved & Cleared'), findsOneWidget);
      expect(find.text('New Batch'), findsOneWidget);
    });

    testWidgets('BatchDetailScreen renders end-to-end lineage traceability with intake lots', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockTrace = ProductionTraceabilityModel(
        batchId: 'pb-01',
        batchNumber: 'BATCH-PAN-20261018-001',
        recordDate: '2026-10-18',
        shift: 'AM',
        productType: ProductType.paneer,
        status: BatchStatus.completed,
        qualityRelease: QualityReleaseStatus.approved,
        expiryDate: '2026-10-25',
        bmcMilkConsumedL: 100.0,
        finishedQuantity: 18.0,
        unitOfMeasure: 'KG',
        yieldPercentage: 18.0,
        lpgUsedKg: 2.0,
        byproductQuantityKg: 80.0,
        processOperator: 'Suresh Kumar',
        createdAt: DateTime.now(),
        intakeLots: [
          const TraceabilityIntakeLot(
            intakeId: 'int-01',
            intakeBatchNumber: 'INT-FRM-001',
            recordDate: '2026-10-18',
            shift: 'AM',
            source: 'FARM',
            supplierRoute: 'Direct Parlour',
            totalIntakeLitres: 150.0,
            litresUsedInBatch: 100.0,
            decision: 'ACCEPTED',
            fatPercentage: 4.20,
            snfPercentage: 8.65,
            temperatureC: 4.2,
            intakeOperator: 'Ramesh Patel',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productionTraceabilityProvider('pb-01').overrideWith((ref) => Future.value(mockTrace)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const BatchDetailScreen(batchId: 'pb-01'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Batch Traceability'), findsOneWidget);
      expect(find.text('BATCH-PAN-20261018-001'), findsOneWidget);
      expect(find.text('End-to-End Lineage Traceability'), findsOneWidget);
      expect(find.text('1. Contributing Raw Milk Intake Lots (1)'), findsOneWidget);
      expect(find.text('INT-FRM-001'), findsOneWidget);
      expect(find.text('100.0 L used'), findsOneWidget);
      expect(find.text('Fat 4.20%'), findsOneWidget);
      expect(find.text('Update QC Status'), findsOneWidget);
    });
  });
}
