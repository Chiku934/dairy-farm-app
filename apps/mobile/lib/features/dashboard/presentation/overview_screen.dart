import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/kpi_card.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Design System Showcase',
            onPressed: () => context.go('/ui-showcase'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary50,
              child: Text('AN', style: TextStyle(color: AppColors.primary800, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top action button
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Record milking', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            // Live status banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, color: AppColors.statusSuccess, size: 10),
                  SizedBox(width: 8),
                  Text(
                    'Live farm records · Dates for India',
                    style: TextStyle(
                      color: AppColors.primary800,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4 Core KPI Stat Cards in Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: const [
                KpiCard(
                  title: 'Milk Recorded',
                  value: '25 L',
                  subtitle: 'Daily yield',
                  icon: Icons.water_drop,
                ),
                KpiCard(
                  title: 'Sales Revenue',
                  value: '₹1,500',
                  subtitle: 'No change',
                  icon: Icons.currency_rupee,
                ),
                KpiCard(
                  title: 'Operating Cost',
                  value: '₹1,616.67',
                  subtitle: 'Daily elapsed cost',
                  icon: Icons.trending_up,
                ),
                KpiCard(
                  title: 'Dry Fertiliser',
                  value: '0 kg',
                  subtitle: 'Biogas stock',
                  icon: Icons.eco,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Manager / Director View Card
            Card(
              color: AppColors.primary900,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MANAGER / DIRECTOR VIEW',
                      style: TextStyle(
                        color: Color(0xAAFFFFFF),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Farm Cost', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13)),
                              SizedBox(height: 4),
                              Text('₹1,336.67', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Production Cost', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13)),
                              SizedBox(height: 4),
                              Text('₹280.00', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Needs Attention Card
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.statusWarning),
                ),
                title: const Text('Reorder Feed', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: const Text('Maize is below safety stock (0 kg remaining)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
