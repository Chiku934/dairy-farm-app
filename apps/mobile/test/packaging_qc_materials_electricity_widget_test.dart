import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dairy_mobile/features/packaging/domain/packaging_models.dart';
import 'package:dairy_mobile/features/packaging/presentation/packaging_provider.dart';
import 'package:dairy_mobile/features/packaging/presentation/packaging_screen.dart';
import 'package:dairy_mobile/features/packaging/presentation/widgets/record_packaging_dialog.dart';

import 'package:dairy_mobile/features/quality/domain/quality_models.dart';
import 'package:dairy_mobile/features/quality/presentation/quality_provider.dart';
import 'package:dairy_mobile/features/quality/presentation/quality_screen.dart';

import 'package:dairy_mobile/features/materials/domain/material_models.dart';
import 'package:dairy_mobile/features/materials/presentation/material_provider.dart';
import 'package:dairy_mobile/features/materials/presentation/materials_screen.dart';

import 'package:dairy_mobile/features/electricity/domain/electricity_models.dart';
import 'package:dairy_mobile/features/electricity/presentation/electricity_provider.dart';
import 'package:dairy_mobile/features/electricity/presentation/electricity_screen.dart';

void main() {
  group('Phase 9: Packaging, Quality, Materials & Electricity Widget Tests', () {
    testWidgets('PackagingScreen renders KPI cards, runs list, and record action', (tester) async {
      final mockRuns = [
        PackagingRunModel(
          id: 'pkg-001',
          recordDate: '2026-10-18',
          productionBatchId: 'batch-001',
          batchNumber: 'BATCH-MILK-001',
          packSize: 0.5,
          packUnit: 'LITRE',
          numberOfPacks: 200,
          totalPackagedQuantity: 100.0,
          packagingItemId: 'item-05',
          materialConsumed: 205.0,
          scrapUnits: 5,
          notes: 'Standard morning milk pouching',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            packagingRunsProvider.overrideWith(
              (ref) => Future.value((items: mockRuns, total: 1, totalPages: 1)),
            ),
          ],
          child: const MaterialApp(
            home: PackagingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Packaging Runs'), findsOneWidget);
      expect(find.text('Packs Produced'), findsOneWidget);
      expect(find.text('200'), findsOneWidget);
      expect(find.text('Batch BATCH-MILK-001'), findsOneWidget);
      expect(find.text('200 packs'), findsOneWidget);
      expect(find.text('100.0 LITRE'), findsOneWidget);
      expect(find.text('Scrap/burst allowance: 5 units'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('RecordPackagingDialog validates empty batch ID on submit', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RecordPackagingDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Submit with empty batch ID
      final recordButton = find.text('Record Run');
      expect(recordButton, findsOneWidget);
      await tester.ensureVisible(recordButton);
      await tester.pumpAndSettle();
      await tester.tap(recordButton);
      await tester.pumpAndSettle();

      expect(find.text('Batch ID is required'), findsOneWidget);
    });

    testWidgets('QualityScreen renders decision filter chips and parameter readings', (tester) async {
      final mockRecords = [
        QualityRecordModel(
          id: 'qc-001',
          recordDate: '2026-10-18',
          targetType: QualityTargetType.productionBatch,
          targetId: 'batch-pan-001',
          fatPercentage: 4.25,
          snfPercentage: 8.80,
          clr: 30.0,
          ph: 6.67,
          temperatureC: 4.2,
          decision: QualityDecision.approved,
          testedBy: 'QC Officer Sharma',
        ),
        QualityRecordModel(
          id: 'qc-002',
          recordDate: '2026-10-18',
          targetType: QualityTargetType.intake,
          targetId: 'int-002',
          fatPercentage: 2.90,
          snfPercentage: 7.80,
          clr: 24.0,
          ph: 6.20,
          temperatureC: 12.0,
          decision: QualityDecision.rejected,
          testedBy: 'BMC Operator',
          notes: 'High acidity and temperature',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            qualityRecordsProvider.overrideWith(
              (ref) => Future.value((items: mockRecords, total: 2, totalPages: 1)),
            ),
          ],
          child: const MaterialApp(
            home: QualityScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Quality Records'), findsOneWidget);
      expect(find.text('Approved'), findsWidgets);
      expect(find.text('Rejected'), findsWidgets);
      expect(find.text('4.25%'), findsOneWidget);
      expect(find.text('8.80%'), findsOneWidget);
      expect(find.textContaining('QC Officer Sharma'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('MaterialsScreen renders department cost cards and stock issue items', (tester) async {
      final mockIssues = [
        MaterialIssueModel(
          id: 'mi-001',
          recordDate: '2026-10-18',
          department: IssueDepartment.production,
          stockItemId: 'item-02',
          stockItemName: 'Caustic Soda Flakes',
          stockItemUnit: 'kg',
          quantity: 10.0,
          unitCost: 45.0,
          totalCost: 450.0,
          issuedTo: 'CIP Operator',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            materialIssuesProvider.overrideWith(
              (ref) => Future.value((items: mockIssues, total: 1, totalPages: 1)),
            ),
          ],
          child: const MaterialApp(
            home: MaterialsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Material Issues'), findsOneWidget);
      expect(find.text('Total Issued'), findsOneWidget);
      expect(find.text('₹450'), findsNWidgets(2));
      expect(find.text('Caustic Soda Flakes'), findsOneWidget);
      expect(find.text('10.0 kg'), findsOneWidget);
      expect(find.text('Issued to: CIP Operator'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('ElectricityScreen renders opening/closing meters and energy costs', (tester) async {
      final mockReadings = [
        ElectricityReadingModel(
          id: 'er-001',
          recordDate: '2026-10-18',
          department: ElectricityDepartment.farm,
          openingReadingKwh: 12000.0,
          closingReadingKwh: 12055.0,
          unitsKwh: 55.0,
          tariffRate: 1.40,
          totalCost: 77.0,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            electricityReadingsProvider.overrideWith(
              (ref) => Future.value((items: mockReadings, total: 1, totalPages: 1)),
            ),
          ],
          child: const MaterialApp(
            home: ElectricityScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Electricity Readings'), findsOneWidget);
      expect(find.text('Total Energy'), findsOneWidget);
      expect(find.text('55 kWh'), findsOneWidget);
      expect(find.text('₹77'), findsOneWidget);
      expect(find.text('12000.0 → 12055.0'), findsOneWidget);
      expect(find.text('₹1.40/kWh'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
