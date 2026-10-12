import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dairy_mobile/features/employees/presentation/employees_screen.dart';
import 'package:dairy_mobile/features/employees/presentation/employee_provider.dart';
import 'package:dairy_mobile/features/employees/domain/employee_models.dart';

import 'package:dairy_mobile/features/licences/presentation/licences_screen.dart';
import 'package:dairy_mobile/features/licences/presentation/licence_provider.dart';
import 'package:dairy_mobile/features/licences/domain/licence_models.dart';

void main() {
  group('Phase 12: Employees and FSSAI & Licences Widget Tests', () {
    // ------------------------------------------------------------------------
    // 1. Employees Screen & Salary Clearance Masking Tests
    // ------------------------------------------------------------------------
    testWidgets('EmployeesScreen renders staff roster, salary clearance, and confidential badges', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockEmployees = [
        const EmployeeModel(
          id: 'emp-01',
          employeeCode: 'EMP-1001',
          fullName: 'Bikash Mohanty',
          department: Department.farm,
          jobTitle: 'Herd Care Specialist',
          joiningDate: '2025-01-15',
          monthlySalary: 36000.0,
          dailySalaryRate: 1200.0,
          status: EmploymentStatus.active,
          phone: '+919437012345',
          email: 'bikash@dairyfarm.local',
        ),
        const EmployeeModel(
          id: 'emp-02',
          employeeCode: 'EMP-1002',
          fullName: 'Subhashree Nayak',
          department: Department.management,
          jobTitle: 'Administrative Officer',
          joiningDate: '2025-02-01',
          monthlySalary: null, // Redacted for unauthorized caller
          dailySalaryRate: null,
          status: EmploymentStatus.active,
          phone: '+919437056789',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            employeesListProvider.overrideWith(
              (ref) => Future.value((items: mockEmployees, total: 2, page: 1, limit: 50)),
            ),
          ],
          child: const MaterialApp(home: EmployeesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title
      expect(find.text('Staff Roster & Personnel'), findsOneWidget);

      // Verify Employee 1 details & unredacted salary
      expect(find.text('Bikash Mohanty'), findsOneWidget);
      expect(find.text('EMP-1001 • Herd Care Specialist'), findsOneWidget);
      expect(find.text('₹36000.00'), findsOneWidget);
      expect(find.text('₹1200.00/day'), findsOneWidget);

      // Verify Employee 2 details & confidential redacted salary badge
      expect(find.text('Subhashree Nayak'), findsOneWidget);
      expect(find.text('EMP-1002 • Administrative Officer'), findsOneWidget);
      expect(find.text('Salary Confidential [REDACTED]'), findsOneWidget);
      expect(find.text('HR Admin & Finance clearance required for wage rates.'), findsOneWidget);

      // Verify Add Employee action button
      expect(find.text('Add Employee'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // 2. Licences Screen & Compliance Status Tests
    // ------------------------------------------------------------------------
    testWidgets('LicencesScreen renders compliance KPI cards, validity period, and reminder chips', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockLicences = [
        const RegulatoryLicenceModel(
          id: 'lic-01',
          licenceName: 'Central FSSAI Dairy Food Safety Licence',
          licenceType: LicenceType.fssai,
          licenceNumber: '10020031000123',
          issuingAuthority: 'FSSAI Eastern Region',
          licenceHolder: 'Green Pastures Organic Dairy Ltd',
          issueDate: '2024-01-01',
          expiryDate: '2027-12-31',
          reminderDaysBefore: 30,
          status: LicenceStatus.active,
          reminderStatus: ReminderStatus.pending,
        ),
        const RegulatoryLicenceModel(
          id: 'lic-02',
          licenceName: 'Pollution Control Consent to Operate',
          licenceType: LicenceType.pollutionControl,
          licenceNumber: 'PCB-OD-2023-451',
          issuingAuthority: 'State Pollution Control Board',
          licenceHolder: 'Green Pastures Organic Dairy Ltd',
          issueDate: '2023-01-01',
          expiryDate: '2026-10-25',
          reminderDaysBefore: 30,
          status: LicenceStatus.expiringSoon,
          reminderStatus: ReminderStatus.notified,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            licencesListProvider.overrideWith(
              (ref) => Future.value((items: mockLicences, total: 2, page: 1, limit: 50)),
            ),
          ],
          child: const MaterialApp(home: LicencesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & KPIs
      expect(find.text('FSSAI & Regulatory Licences'), findsOneWidget);
      expect(find.text('Total Licences'), findsOneWidget);
      expect(find.text('Expiring Soon'), findsWidgets); // In KPI and status badge

      // Verify Licence 1 details
      expect(find.text('Central FSSAI Dairy Food Safety Licence'), findsOneWidget);
      expect(find.text('Reg: 10020031000123 • FSSAI Food Safety'), findsOneWidget);
      expect(find.text('Authority: FSSAI Eastern Region'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);

      // Verify Licence 2 details
      expect(find.text('Pollution Control Consent to Operate'), findsOneWidget);
      expect(find.text('Reg: PCB-OD-2023-451 • Pollution Control (PCB)'), findsOneWidget);
      expect(find.text('Reminder Sent'), findsOneWidget);

      // Verify action buttons
      expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
      expect(find.text('Register Licence'), findsOneWidget);
    });
  });
}
