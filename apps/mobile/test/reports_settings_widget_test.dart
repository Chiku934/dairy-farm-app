import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dairy_mobile/features/reports/presentation/reports_screen.dart';
import 'package:dairy_mobile/features/reports/presentation/reports_provider.dart';
import 'package:dairy_mobile/features/reports/domain/report_models.dart';

import 'package:dairy_mobile/features/settings/presentation/settings_screen.dart';
import 'package:dairy_mobile/features/settings/presentation/settings_provider.dart';
import 'package:dairy_mobile/features/settings/domain/settings_models.dart';

class MockStaffPayrollFilterNotifier extends ReportFilterNotifier {
  @override
  ReportFilterState build() => const ReportFilterState(selectedType: ReportType.staffPayroll);
}

void main() {
  group('Phase 13: Reports & Exports and Farm Settings Widget Tests', () {
    // ------------------------------------------------------------------------
    // 1. Reports & Exports Screen Tests
    // ------------------------------------------------------------------------
    testWidgets('ReportsScreen renders report selector, KPI metrics, preview table, and export button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const mockSummary = {
        'totalYieldLitres': 2450.5,
        'withheldLitres': 85.0,
        'recordCount': 120,
      };

      final mockItems = [
        {
          'record_date': '2026-10-10',
          'session': 'MORNING',
          'ear_tag': 'TAG-001',
          'yield_litres': 16.5,
          'disposition': 'ELIGIBLE',
        },
        {
          'record_date': '2026-10-10',
          'session': 'EVENING',
          'ear_tag': 'TAG-002',
          'yield_litres': 5.0,
          'disposition': 'WITHHELD',
        },
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeReportDataProvider.overrideWith(
              (ref) => Future.value(
                ReportResultModel(
                  summary: mockSummary,
                  items: mockItems,
                  total: 2,
                  page: 1,
                  limit: 50,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: ReportsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & report type choices
      expect(find.text('Enterprise Reports & Exports'), findsOneWidget);
      expect(find.text('Milk Production & Yield'), findsOneWidget);
      expect(find.text('Sales & Customer Revenue'), findsOneWidget);
      expect(find.text('Operating Expenses & Costs'), findsOneWidget);
      expect(find.text('Herd Inventory & Health Status'), findsOneWidget);
      expect(find.text('Feed & Stock Valuation'), findsOneWidget);
      expect(find.text('Staff Directory & Wage Rates'), findsOneWidget);

      // Verify KPI Metrics
      expect(find.text('Total Yield'), findsOneWidget);
      expect(find.text('2450.5 L'), findsOneWidget);
      expect(find.text('Withheld Volume'), findsOneWidget);
      expect(find.text('85.0 L'), findsOneWidget);

      // Verify Data Records & Table
      expect(find.text('Data Records (2 total)'), findsOneWidget);
      expect(find.text('TAG-001'), findsOneWidget);
      expect(find.text('TAG-002'), findsOneWidget);

      // Verify Export CSV Action button
      expect(find.text('Export CSV'), findsOneWidget);
    });

    testWidgets('ReportsScreen displays security alert for confidential staff payroll report', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const mockSummary = {
        'totalEmployees': 12,
        'activeEmployees': 10,
        'totalMonthlySalary': 380000.0,
        'totalDailyRate': 12666.67,
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportFilterProvider.overrideWith(MockStaffPayrollFilterNotifier.new),
            activeReportDataProvider.overrideWith(
              (ref) => Future.value(
                const ReportResultModel(
                  summary: mockSummary,
                  items: [],
                  total: 0,
                  page: 1,
                  limit: 50,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: ReportsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify confidential banner appears
      expect(
        find.text('Confidential Data: Staff salaries & wage rates require HR Admin or Finance clearance.'),
        findsOneWidget,
      );
    });

    // ------------------------------------------------------------------------
    // 2. Settings Screen & Parameter Cards Tests
    // ------------------------------------------------------------------------
    testWidgets('SettingsScreen renders farm identity, operating tariffs, and edit button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const mockSettings = FarmSettingsModel(
        farmName: 'Kaivalya Organic Dairy',
        address: 'Dandiri Farm Complex',
        district: 'Koraput',
        state: 'Odisha',
        pincode: '764036',
        contactPhone: '+91 9437012345',
        contactEmail: 'contact@kaivalyadairy.com',
        bmcCapacityLitres: 2500.0,
        electricityTariff: 1.5,
        feedBaseKg: 1.2,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            farmSettingsProvider.overrideWith((ref) => Future.value(mockSettings)),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AppBar & Card Titles
      expect(find.text('Farm Settings & Identity'), findsOneWidget);
      expect(find.text('FARM IDENTITY & PROFILE'), findsOneWidget);
      expect(find.text('OPERATIONAL PARAMETERS & TARIFFS'), findsOneWidget);
      expect(find.text('MASTER UNITS & TAXONOMIES'), findsOneWidget);

      // Verify Identity Values
      expect(find.text('Kaivalya Organic Dairy'), findsOneWidget);
      expect(find.text('Dandiri Farm Complex, Koraput, Odisha - 764036'), findsOneWidget);

      // Verify Tariff & Operational Values
      expect(find.text('2500 Litres'), findsOneWidget);
      expect(find.text('₹1.50 per unit (kWh)'), findsOneWidget);

      // Verify Edit Parameters button
      expect(find.text('Edit Parameters'), findsOneWidget);

      // Tap Edit Parameters and verify EditSettingsDialog mounts
      await tester.tap(find.text('Edit Parameters'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Farm Operating Parameters'), findsOneWidget);
      expect(find.text('Save Parameters'), findsOneWidget);
    });
  });
}
