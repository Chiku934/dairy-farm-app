import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dairy_mobile/features/dashboard/presentation/overview_screen.dart';
import 'package:dairy_mobile/features/dashboard/presentation/dashboard_provider.dart';
import 'package:dairy_mobile/features/dashboard/domain/dashboard_models.dart';
import 'package:dairy_mobile/features/dashboard/presentation/widgets/dashboard_skeleton_view.dart';
import 'package:dairy_mobile/features/dashboard/presentation/widgets/dashboard_error_view.dart';
import 'package:dairy_mobile/features/dashboard/presentation/widgets/dashboard_empty_view.dart';
import 'package:dairy_mobile/features/auth/presentation/auth_provider.dart';
import 'package:dairy_mobile/features/auth/domain/user_session.dart';

void main() {
  final sampleDashboardData = DashboardOverviewModel(
    periodType: 'today',
    startDate: '2026-10-11',
    endDate: '2026-10-11',
    periodLabel: 'Today',
    milkRecorded: const KpiMetricModel(
      value: 57.5,
      unit: 'L',
      label: 'Milk Recorded',
      priorValue: 72.4,
      deltaPercent: -20.6,
      amYield: 31.5,
      pmYield: 26.0,
    ),
    dryFertiliser: const KpiMetricModel(
      value: 75.0,
      unit: 'kg',
      label: 'Dry Fertiliser Output',
      priorValue: 85.0,
      deltaPercent: -11.8,
    ),
    salesRevenue: const KpiMetricModel(
      value: 2740.0,
      currency: '₹',
      label: 'Sales Revenue',
      priorValue: 3200.0,
      deltaPercent: -14.4,
    ),
    operatingCost: const KpiMetricModel(
      value: 1867.20,
      currency: '₹',
      label: 'Operating Cost',
      priorValue: 2172.80,
      deltaPercent: -14.1,
    ),
    costPerLitre: const CostPerLitreModel(
      value: 32.47,
      currency: '₹',
      label: 'Cost per Litre',
      status: 'CALCULATED',
      formulaExplanation: '₹1867.20 total cost / 57.50 L milk',
    ),
    herd: const HerdSummaryModel(
      totalActive: 9,
      lactating: 4,
      dry: 1,
      pregnant: 1,
      heifersCalves: 2,
      bulls: 1,
    ),
    bmcTank: const BmcStatusModel(
      capacityLitres: 2000.0,
      currentBalanceLitres: 105.4,
      utilizationPercent: 5.3,
      status: 'NORMAL',
    ),
    totalAlertsCount: 2,
    alerts: const [
      DashboardAlertModel(
        id: 'alert-1',
        type: 'EXPIRING_LICENCE',
        severity: 'WARNING',
        title: 'FSSAI Licence Expiring Soon',
        description: 'Expires in 20 days',
        daysRemaining: 20,
      ),
      DashboardAlertModel(
        id: 'alert-2',
        type: 'WITHDRAWAL_WARNING',
        severity: 'CRITICAL',
        title: 'Active Milk Safety Withdrawal',
        description: 'Milk withheld for treatment',
        daysRemaining: 2,
      ),
    ],
    dailyYields: const [
      DailyYieldTrendModel(
        date: '2026-10-10',
        morningYield: 31.5,
        eveningYield: 26.0,
        totalYield: 57.5,
      ),
    ],
    dailyRevenue: const [
      DailyRevenueTrendModel(date: '2026-10-10', amount: 2740.0),
    ],
    recentActivity: [
      RecentActivityModel(
        id: 'act-1',
        timestamp: DateTime.now(),
        category: 'MILKING',
        title: 'Milking Recorded: TAG-101',
        description: 'Morning session: 13.50 L (ELIGIBLE)',
        badge: '13.50 L',
      ),
    ],
  );

  Widget createTestWidget({
    required List<dynamic> overrides,
  }) {
    return ProviderScope(
      overrides: overrides.cast(),
      child: const MaterialApp(
        home: OverviewScreen(),
      ),
    );
  }

  group('Phase 5: Dairy Farm Dashboard Flutter Widget Tests', () {
    testWidgets('renders skeleton loading view when overview is loading', (tester) async {
      final completer = Completer<DashboardOverviewModel>();
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            dashboardOverviewProvider.overrideWith((ref) => completer.future),
          ],
        ),
      );

      // Verify skeleton is mounted
      expect(find.byType(DashboardSkeletonView), findsOneWidget);
    });

    testWidgets('renders DashboardErrorView with retry button and error details', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardErrorView(
              errorMessage: 'Network connection failed',
              onRetry: () {
                retried = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(DashboardErrorView), findsOneWidget);
      expect(find.text('Failed to Load Dashboard'), findsOneWidget);
      expect(find.text('Network connection failed'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });

    testWidgets('renders DashboardEmptyView with period reset button', (tester) async {
      bool resetCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardEmptyView(
              onResetPeriod: () {
                resetCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(DashboardEmptyView), findsOneWidget);
      expect(find.text('No Farm Records for Period'), findsOneWidget);
      expect(find.text('View Today\'s Records'), findsOneWidget);

      await tester.tap(find.text('View Today\'s Records'));
      expect(resetCalled, isTrue);
    });

    testWidgets('renders full KPI cards, BMC status, herd counts and alerts when data is loaded', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            dashboardOverviewProvider.overrideWith((ref) => Future.value(sampleDashboardData)),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Verify 4 Core KPI cards
      expect(find.text('Milk Recorded'), findsOneWidget);
      expect(find.text('57.5 L'), findsOneWidget);
      expect(find.text('AM: 31.5 L · PM: 26.0 L'), findsOneWidget);

      expect(find.text('Sales Revenue'), findsOneWidget);
      expect(find.text('₹2740'), findsOneWidget);

      expect(find.text('Operating Cost'), findsOneWidget);
      expect(find.text('₹1867.20'), findsOneWidget);

      expect(find.text('Dry Fertiliser'), findsOneWidget);
      expect(find.text('75.0 kg'), findsOneWidget);

      // Verify Unit Milk Costing Banner
      expect(find.text('Unit Milk Cost: '), findsOneWidget);
      expect(find.text('₹32.47 / Litre'), findsOneWidget);

      // Verify BMC Tank Status Card
      expect(find.text('Bulk Milk Cooler (BMC)'), findsOneWidget);
      expect(find.text('Live Tank Balance: 105.4 L'), findsOneWidget);
      expect(find.text('5.3% (2000 L cap)'), findsOneWidget);

      // Verify Herd Summary
      expect(find.text('Active Herd Composition'), findsOneWidget);
      expect(find.text('9 Cattle'), findsOneWidget);
      expect(find.text('Lactating'), findsOneWidget);

      // Verify Alerts
      expect(find.text('Attention & Action Required'), findsOneWidget);
      expect(find.text('FSSAI Licence Expiring Soon'), findsOneWidget);
      expect(find.text('Active Milk Safety Withdrawal'), findsOneWidget);

      // Verify Date Filter Chips
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Last 7 Days'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Custom Range'), findsOneWidget);
    });

    testWidgets('enforces RBAC data masking when financial records are restricted', (tester) async {
      final restrictedDashboardData = DashboardOverviewModel(
        periodType: 'today',
        startDate: '2026-10-11',
        endDate: '2026-10-11',
        periodLabel: 'Today',
        milkRecorded: sampleDashboardData.milkRecorded,
        dryFertiliser: sampleDashboardData.dryFertiliser,
        salesRevenue: null, // REDACTED BY BACKEND
        operatingCost: null, // REDACTED BY BACKEND
        costPerLitre: const CostPerLitreModel(
          value: null,
          currency: '₹',
          label: 'Cost per Litre',
          status: 'RESTRICTED',
          formulaExplanation: 'Financial records restricted to authorized roles',
        ),
        herd: sampleDashboardData.herd,
        bmcTank: sampleDashboardData.bmcTank,
        totalAlertsCount: 0,
        alerts: const [],
        dailyYields: sampleDashboardData.dailyYields,
        dailyRevenue: null,
        recentActivity: sampleDashboardData.recentActivity,
      );

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            dashboardOverviewProvider.overrideWith((ref) => Future.value(restrictedDashboardData)),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Operational metrics remain visible
      expect(find.text('Milk Recorded'), findsOneWidget);
      expect(find.text('57.5 L'), findsOneWidget);

      // Financial figures MUST NOT appear; "Restricted" card state must be rendered
      expect(find.text('₹2740'), findsNothing);
      expect(find.text('₹1867.20'), findsNothing);
      expect(find.text('Restricted'), findsWidgets);
      expect(find.text('Finance authorization required'), findsWidgets);
    });

    testWidgets('displays read-only notice when auditor role is logged in', (tester) async {
      final auditorSession = UserSession(
        accessToken: 'mock_token',
        refreshToken: 'mock_refresh',
        expiresInSeconds: 900,
        user: const UserProfile(
          id: 'usr-auditor',
          email: 'auditor@dairyfarm.local',
          fullName: 'Vikram Sen',
          roles: ['AUDITOR'],
          permissions: ['animals:read', 'milking:read', 'finance:read'],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardOverviewProvider.overrideWith((ref) => Future.value(sampleDashboardData)),
            authProvider.overrideWith(() => AuthNotifierMock(auditorSession)),
          ],
          child: const MaterialApp(
            home: OverviewScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Auditor Mode Active: Read-only access enabled across all records.'),
        findsOneWidget,
      );
      // Action chips like "Log Milking" must be hidden for auditor
      expect(find.text('Log Milking'), findsNothing);
    });
  });
}

class AuthNotifierMock extends AuthNotifier {
  final UserSession _mockSession;
  AuthNotifierMock(this._mockSession);

  @override
  AuthState build() {
    return Authenticated(_mockSession);
  }
}
