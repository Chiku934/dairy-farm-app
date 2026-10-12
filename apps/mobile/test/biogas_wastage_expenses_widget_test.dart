import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dairy_mobile/features/biogas/presentation/biogas_screen.dart';
import 'package:dairy_mobile/features/biogas/presentation/biogas_provider.dart';
import 'package:dairy_mobile/features/biogas/domain/biogas_models.dart';

import 'package:dairy_mobile/features/wastage/presentation/wastage_screen.dart';
import 'package:dairy_mobile/features/wastage/presentation/wastage_provider.dart';
import 'package:dairy_mobile/features/wastage/domain/wastage_models.dart';

import 'package:dairy_mobile/features/expenses/presentation/expenses_screen.dart';
import 'package:dairy_mobile/features/expenses/presentation/expense_provider.dart';
import 'package:dairy_mobile/features/expenses/domain/expense_models.dart';

void main() {
  group('Phase 11: Biogas Fertiliser, Wastage & Losses and Costs & Expenses Widget Tests', () {
    // ------------------------------------------------------------------------
    // 1. Biogas Screen Tests
    // ------------------------------------------------------------------------
    testWidgets('BiogasScreen renders KPI summary cards, filter chips, and runs list', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const mockSummary = BiogasSummaryModel(
        totalSlurryInputKg: 1000.0,
        totalDryFertiliserKg: 180.0,
        totalPackedBags: 18,
        overallYieldPct: 18.0,
        internalFarmKg: 80.0,
        directSaleKg: 0.0,
        storeStockKg: 100.0,
      );

      final mockRuns = [
        BiogasRunModel(
          id: 'bio-01',
          runNumber: 'BIO-202610-001',
          recordDate: '2026-10-12',
          slurryInputKg: 1000.0,
          dryFertiliserOutputKg: 180.0,
          moisturePct: 14.5,
          usageType: BiogasUsageType.storeStock,
          bags1kg: 10,
          bags5kg: 10,
          bags25kg: 2,
          bags50kg: 1,
          yieldPct: 18.0,
          totalPackedKg: 160.0,
          notes: 'Solar drying bed test batch',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            biogasRunsProvider.overrideWith(
              (ref) => Future.value((items: mockRuns, total: 1, totalPages: 1, summary: mockSummary)),
            ),
          ],
          child: const MaterialApp(home: BiogasScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & KPIs
      expect(find.text('Biogas & Bio-Fertiliser'), findsOneWidget);
      expect(find.text('1000 kg'), findsOneWidget);
      expect(find.text('180 kg'), findsOneWidget);
      expect(find.text('18.0%'), findsOneWidget); // KPI card
      expect(find.text('Yield: 18.0%'), findsOneWidget); // Yield tag on card
      expect(find.text('18'), findsOneWidget); // Packed bags

      // Verify Run card details
      expect(find.text('BIO-202610-001'), findsOneWidget);
      expect(find.text('Store in Farm Inventory'), findsNWidgets(2)); // Filter chip + Card badge
      expect(find.text('Notes: Solar drying bed test batch'), findsOneWidget);

      // Verify Floating Action Button
      expect(find.text('Record Run'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // 2. Wastage Screen Tests
    // ------------------------------------------------------------------------
    testWidgets('WastageScreen renders incidents, valuation loss, and filter chips', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const mockSummary = WastageSummaryModel(
        totalIncidents: 2,
        totalEstimatedLoss: 2200.0,
        bmcLossLitres: 50.0,
        supplyLossValue: 600.0,
      );

      final mockRecords = [
        WastageRecordModel(
          id: 'wst-01',
          wastageNumber: 'WST-202610-001',
          recordDate: '2026-10-12',
          stockType: StockType.supply,
          referenceId: 'LOT-BOXES-01',
          stockItemName: 'Packaging Boxes 500ml',
          quantityLost: 15.0,
          unit: 'PCS',
          reason: WastageReason.handling,
          estimatedLossCost: 600.0,
          notes: 'Crushed cartons during reorganizing',
        ),
        WastageRecordModel(
          id: 'wst-02',
          wastageNumber: 'WST-202610-002',
          recordDate: '2026-10-12',
          stockType: StockType.bmc,
          referenceId: 'BMC-SILO-01',
          quantityLost: 50.0,
          unit: 'L',
          reason: WastageReason.spoilage,
          estimatedLossCost: 1600.0,
          notes: 'Power disruption chiller cutoff',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wastageRecordsProvider.overrideWith(
              (ref) => Future.value((items: mockRecords, total: 2, totalPages: 1, summary: mockSummary)),
            ),
          ],
          child: const MaterialApp(home: WastageScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen title
      expect(find.text('Wastage & Losses'), findsOneWidget);

      // Verify KPIs
      expect(find.text('2'), findsOneWidget); // Total incidents
      expect(find.text('₹2200'), findsOneWidget); // Total loss cost
      expect(find.text('₹600'), findsOneWidget); // Supply write-offs

      // Verify incident cards
      expect(find.text('WST-202610-001'), findsOneWidget);
      expect(find.text('WST-202610-002'), findsOneWidget);
      expect(find.text('15.0 PCS'), findsOneWidget);
      expect(find.text('50.0 L'), findsNWidgets(2)); // KPI card + card quantity
      expect(find.text('Loss: ₹600.00'), findsOneWidget);
      expect(find.text('Loss: ₹1600.00'), findsOneWidget);

      // Verify FAB
      expect(find.text('Record Wastage'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // 3. Operating Expenses Screen Tests
    // ------------------------------------------------------------------------
    testWidgets('ExpensesScreen renders cost centres, summary totals, and expense cards', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const mockSummary = ExpenseSummaryModel(
        totalExpenses: 4750.5,
        farmExpenses: 2500.0,
        productionExpenses: 1450.5,
        biogasExpenses: 800.0,
      );

      final mockExpenses = [
        OperatingExpenseModel(
          id: 'exp-01',
          expenseNumber: 'EXP-202610-001',
          recordDate: '2026-10-12',
          costCentre: CostCentre.production,
          category: ExpenseCategory.cleaning,
          amount: 1450.5,
          payee: 'CleanTech Chemical Supplies',
          invoiceNumber: 'INV-7842',
          paymentMethod: PaymentMethod.upi,
          notes: 'CIP acid detergent drums',
        ),
        OperatingExpenseModel(
          id: 'exp-02',
          expenseNumber: 'EXP-202610-002',
          recordDate: '2026-10-12',
          costCentre: CostCentre.farm,
          category: ExpenseCategory.maintenance,
          amount: 2500.0,
          payee: 'Tractor Repair Workshop',
          invoiceNumber: 'INV-4120',
          paymentMethod: PaymentMethod.bankTransfer,
          notes: 'Hydraulic pump replacement',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            operatingExpensesProvider.overrideWith(
              (ref) => Future.value((items: mockExpenses, total: 2, totalPages: 1, summary: mockSummary)),
            ),
          ],
          child: const MaterialApp(home: ExpensesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & KPIs
      expect(find.text('Costs & Operating Expenses'), findsOneWidget);
      expect(find.text('₹4751'), findsOneWidget); // Rounded 4750.5
      expect(find.text('₹2500'), findsOneWidget);
      expect(find.text('₹1451'), findsOneWidget);
      expect(find.text('₹800'), findsOneWidget);

      // Verify expense cards
      expect(find.text('EXP-202610-001'), findsOneWidget);
      expect(find.text('EXP-202610-002'), findsOneWidget);
      expect(find.text('₹1450.50'), findsOneWidget);
      expect(find.text('₹2500.00'), findsOneWidget);
      expect(find.text('CleanTech Chemical Supplies'), findsOneWidget);
      expect(find.text('Tractor Repair Workshop'), findsOneWidget);

      // Verify FAB
      expect(find.text('Record Expense'), findsOneWidget);
    });
  });
}
