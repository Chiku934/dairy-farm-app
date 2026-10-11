import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../auth/presentation/auth_provider.dart';
import 'dashboard_provider.dart';
import '../domain/dashboard_models.dart';
import 'widgets/dashboard_date_filter_bar.dart';
import 'widgets/dashboard_kpi_cards.dart';
import 'widgets/bmc_tank_progress_card.dart';
import 'widgets/herd_summary_section.dart';
import 'widgets/dashboard_alerts_section.dart';
import 'widgets/dashboard_trends_chart.dart';
import 'widgets/recent_activity_section.dart';
import 'widgets/dashboard_quick_actions.dart';
import 'widgets/dashboard_skeleton_view.dart';
import 'widgets/dashboard_error_view.dart';
import 'widgets/dashboard_empty_view.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).session;
    final overviewAsync = ref.watch(dashboardOverviewProvider);

    final userInitials = (session?.fullName.isNotEmpty ?? false)
        ? session!.fullName
            .trim()
            .split(' ')
            .take(2)
            .map((s) => s[0].toUpperCase())
            .join()
        : 'KD';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Metrics',
            onPressed: () {
              ref.invalidate(dashboardOverviewProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Design System Showcase',
            onPressed: () => context.go('/ui-showcase'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary50,
              child: Text(
                userInitials,
                style: const TextStyle(
                  color: AppColors.primary800,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/'),
      body: RefreshIndicator(
        color: AppColors.primary700,
        onRefresh: () async {
          ref.invalidate(dashboardOverviewProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Role-Aware Quick Operations Bar
              const DashboardQuickActions(),
              const SizedBox(height: 14),

              // 2. Live Database Status Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: AppColors.statusSuccess, size: 9),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        session != null
                            ? 'Live Farm Records · ${session.primaryRoleTitle}'
                            : 'Live Farm Records · Real-Time Mode',
                        style: const TextStyle(
                          color: AppColors.primary800,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Text(
                      'IST (UTC+5:30)',
                      style: TextStyle(
                        color: AppColors.primary700,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Date Filter Bar (Today, Last 7 Days, This Month, Custom)
              const DashboardDateFilterBar(),
              const SizedBox(height: 16),

              // 4. Async Dashboard Content (Skeleton / Error / Empty / Loaded)
              overviewAsync.when(
                loading: () => const DashboardSkeletonView(),
                error: (error, _) => DashboardErrorView(
                  errorMessage: error.toString().replaceFirst('Exception: ', ''),
                  onRetry: () => ref.refresh(dashboardOverviewProvider),
                ),
                data: (data) {
                  final hasNoRecords = data.milkRecorded.value == 0 &&
                      data.dryFertiliser.value == 0 &&
                      (data.salesRevenue?.value ?? 0) == 0;

                  if (hasNoRecords && data.periodType == 'custom') {
                    return DashboardEmptyView(
                      onResetPeriod: () {
                        ref.read(dashboardPeriodFilterProvider.notifier).setFilter(
                              DashboardPeriodFilter.today,
                            );
                      },
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 4 Primary KPI Summary Cards + Cost per Litre Banner
                      DashboardKpiCards(data: data),
                      const SizedBox(height: 16),

                      // Live BMC Tank Capacity & Utilization Gauge
                      BmcTankProgressCard(bmc: data.bmcTank),
                      const SizedBox(height: 16),

                      // Active Herd Composition Breakdown
                      HerdSummarySection(herd: data.herd),
                      const SizedBox(height: 16),

                      // Actionable Operational Alerts
                      DashboardAlertsSection(alerts: data.alerts),
                      const SizedBox(height: 16),

                      // Daily Production & Yield Trends Chart
                      DashboardTrendsChart(
                        dailyYields: data.dailyYields,
                        dailyRevenue: data.dailyRevenue,
                      ),
                      const SizedBox(height: 16),

                      // Recent Chronological Operations Feed
                      RecentActivitySection(activities: data.recentActivity),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
