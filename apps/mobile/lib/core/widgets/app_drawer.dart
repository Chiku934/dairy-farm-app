import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  final bool isPersistent;

  const AppDrawer({
    super.key,
    required this.currentRoute,
    this.isPersistent = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget drawerContent = Container(
      color: AppColors.primary900,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Branded Drawer Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0x22FFFFFF), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.primary600, width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.pets, color: AppColors.primary800, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kaivalya Dairy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Dandiri · Odisha',
                          style: TextStyle(
                            color: Color(0xCCFFFFFF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Menu Groups
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildSectionHeader('YOUR DAIRY'),
                  _buildNavItem(context, 'Overview', Icons.dashboard_outlined, '/'),
                  _buildNavItem(context, 'Herd & calves', Icons.format_list_bulleted, '/herd'),
                  _buildNavItem(context, 'Milking log', Icons.water_drop_outlined, '/milking'),
                  _buildNavItem(context, 'Health & vaccination', Icons.medical_services_outlined, '/health'),
                  _buildNavItem(context, 'Breeding & calving', Icons.favorite_border, '/breeding'),
                  _buildNavItem(context, 'Feed & ration planning', Icons.grass_outlined, '/feed'),
                  _buildNavItem(context, 'Unit costing', Icons.calculate_outlined, '/costing'),

                  const SizedBox(height: 8),
                  _buildSectionHeader('MILK TO MARKET'),
                  _buildNavItem(context, 'BMC & milk intake', Icons.local_shipping_outlined, '/bmc'),
                  _buildNavItem(context, 'Production batches', Icons.blender_outlined, '/batches'),
                  _buildNavItem(context, 'Packaging', Icons.inventory_2_outlined, '/packaging'),
                  _buildNavItem(context, 'Quality records', Icons.verified_outlined, '/quality'),
                  _buildNavItem(context, 'Material issues', Icons.outbox_outlined, '/materials'),
                  _buildNavItem(context, 'Electricity readings', Icons.bolt_outlined, '/electricity'),
                  _buildNavItem(context, 'Orders & dispatch', Icons.assignment_outlined, '/orders'),
                  _buildNavItem(context, 'Sales', Icons.point_of_sale_outlined, '/sales'),
                  _buildNavItem(context, 'Customer payments', Icons.payments_outlined, '/payments'),

                  const SizedBox(height: 8),
                  _buildSectionHeader('BUSINESS'),
                  _buildNavItem(context, 'Common inventory', Icons.warehouse_outlined, '/inventory'),
                  _buildNavItem(context, 'Biogas fertiliser', Icons.eco_outlined, '/biogas'),
                  _buildNavItem(context, 'Wastage & losses', Icons.delete_sweep_outlined, '/wastage'),
                  _buildNavItem(context, 'Costs & expenses', Icons.receipt_long_outlined, '/expenses'),
                  _buildNavItem(context, 'Employees', Icons.people_outline, '/employees'),
                  _buildNavItem(context, 'FSSAI & licences', Icons.policy_outlined, '/licences'),
                  _buildNavItem(context, 'Reports & exports', Icons.bar_chart_outlined, '/reports'),
                  _buildNavItem(context, 'Farm settings', Icons.settings_outlined, '/settings'),

                  const SizedBox(height: 8),
                  _buildSectionHeader('DESIGN SYSTEM'),
                  _buildNavItem(context, 'UI Showcase', Icons.palette_outlined, '/ui-showcase'),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isPersistent) {
      return drawerContent;
    }

    return Drawer(
      backgroundColor: AppColors.primary900,
      child: drawerContent,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0x88FFFFFF),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, IconData icon, String path) {
    final isSelected = currentRoute == path;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (!isPersistent) {
            Navigator.of(context).pop(); // Close drawer on mobile
          }
          if (!isSelected) {
            context.go(path);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary700 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xBBFFFFFF),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xDDFFFFFF),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.mint,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
