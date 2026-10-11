import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/dashboard/presentation/overview_screen.dart';
import '../features/herd/presentation/herd_screen.dart';
import '../features/milking/presentation/milking_screen.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/costing/presentation/costing_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/showcase/presentation/ui_showcase_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../core/widgets/app_drawer.dart';

class ModulePlaceholderScreen extends StatelessWidget {
  final String title;
  final String path;

  const ModulePlaceholderScreen({super.key, required this.title, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: AppDrawer(currentRoute: path),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Module scaffold ready for Phase implementation: $path',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const OverviewScreen(),
    ),
    GoRoute(
      path: '/herd',
      builder: (context, state) => const HerdScreen(),
    ),
    GoRoute(
      path: '/milking',
      builder: (context, state) => const MilkingScreen(),
    ),
    GoRoute(
      path: '/health',
      builder: (context, state) => const ModulePlaceholderScreen(title: 'Health & Vaccination', path: '/health'),
    ),
    GoRoute(
      path: '/breeding',
      builder: (context, state) => const ModulePlaceholderScreen(title: 'Breeding & Calving', path: '/breeding'),
    ),
    GoRoute(
      path: '/feed',
      builder: (context, state) => const FeedScreen(),
    ),
    GoRoute(
      path: '/costing',
      builder: (context, state) => const CostingScreen(),
    ),
    GoRoute(
      path: '/bmc',
      builder: (context, state) => const ModulePlaceholderScreen(title: 'BMC & Milk Intake', path: '/bmc'),
    ),
    GoRoute(
      path: '/batches',
      builder: (context, state) => const ModulePlaceholderScreen(title: 'Production Batches', path: '/batches'),
    ),
    GoRoute(
      path: '/packaging',
      builder: (context, state) => const ModulePlaceholderScreen(title: 'Packaging', path: '/packaging'),
    ),
    GoRoute(
      path: '/quality',
      builder: (context, state) => const ModulePlaceholderScreen(title: 'Quality Records', path: '/quality'),
    ),
    GoRoute(
      path: '/materials',
      builder: (context, state) => const ModulePlaceholderScreen(title: 'Material Issues', path: '/materials'),
    ),
    GoRoute(
      path: '/electricity',
      builder: (context, state) => const ModulePlaceholderScreen(title: 'Electricity Readings', path: '/electricity'),
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const ModulePlaceholderScreen(title: 'Orders & Dispatch', path: '/orders'),
    ),
    GoRoute(
      path: '/sales',
      builder: (context, state) => const ModulePlaceholderScreen(title: 'Sales', path: '/sales'),
    ),
    GoRoute(
      path: '/payments',
      builder: (context, state) => const ModulePlaceholderScreen(title: 'Customer Payments', path: '/payments'),
    ),
    GoRoute(
      path: '/inventory',
      builder: (context, state) => const ModulePlaceholderScreen(title: 'Common Inventory', path: '/inventory'),
    ),
    GoRoute(
      path: '/biogas',
      builder: (context, state) => const ModulePlaceholderScreen(title: 'Biogas Fertiliser', path: '/biogas'),
    ),
    GoRoute(
      path: '/wastage',
      builder: (context, state) => const ModulePlaceholderScreen(title: 'Wastage & Losses', path: '/wastage'),
    ),
    GoRoute(
      path: '/expenses',
      builder: (context, state) => const ModulePlaceholderScreen(title: 'Costs & Expenses', path: '/expenses'),
    ),
    GoRoute(
      path: '/employees',
      builder: (context, state) => const ModulePlaceholderScreen(title: 'Employees', path: '/employees'),
    ),
    GoRoute(
      path: '/licences',
      builder: (context, state) => const ModulePlaceholderScreen(title: 'FSSAI & Licences', path: '/licences'),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ModulePlaceholderScreen(title: 'Reports & Exports', path: '/reports'),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/ui-showcase',
      builder: (context, state) => const UIShowcaseScreen(),
    ),
  ],
);
