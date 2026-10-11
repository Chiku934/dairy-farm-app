import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/domain/user_session.dart';

class AppDrawer extends ConsumerWidget {
  final String currentRoute;
  final bool isPersistent;

  const AppDrawer({
    super.key,
    required this.currentRoute,
    this.isPersistent = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.session.user : null;

    Widget drawerContent = Container(
      color: AppColors.primary900,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Branded Drawer Header with User Profile Badge
            _buildHeader(context, user),

            // Navigation Menu Groups
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ..._buildYourDairySection(context, user),
                  ..._buildMilkToMarketSection(context, user),
                  ..._buildBusinessSection(context, user),

                  const SizedBox(height: 8),
                  _buildSectionHeader('SYSTEM & DEMO'),
                  _buildNavItem(context, 'UI Showcase', Icons.palette_outlined, '/ui-showcase'),
                ],
              ),
            ),

            // Logout Footer
            _buildLogoutFooter(context, ref, user),
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

  Widget _buildHeader(BuildContext context, UserProfile? user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x22FFFFFF), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary600, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.pets, color: AppColors.primary800, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Kaivalya Dairy',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? 'Dandiri · Odisha',
                      style: const TextStyle(
                        color: Color(0xBBFFFFFF),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _getRoleBadgeColor(user).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _getRoleBadgeColor(user).withOpacity(0.6)),
              ),
              child: Text(
                user.primaryRoleDisplayName,
                style: TextStyle(
                  color: _getRoleBadgeColor(user),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRoleBadgeColor(UserProfile user) {
    if (user.isOwner) return AppColors.mint;
    if (user.isAccountant) return const Color(0xFF93C5FD);
    if (user.isAuditor) return const Color(0xFFFDE68A);
    if (user.isStorekeeper) return const Color(0xFFFDBA74);
    return Colors.white;
  }

  List<Widget> _buildYourDairySection(BuildContext context, UserProfile? user) {
    // Determine permissions
    final canViewHerd = user == null || user.isOwner || user.isManager || user.isAnimalCare || user.isAuditor;
    final canViewMilking = canViewHerd || (user?.roles.contains('MILKING_STAFF') ?? false);
    final canViewCosting = user == null || user.isOwner || user.isManager || user.isAccountant || user.isAuditor;

    return [
      _buildSectionHeader('YOUR DAIRY'),
      _buildNavItem(context, 'Overview', Icons.dashboard_outlined, '/'),
      if (canViewHerd) _buildNavItem(context, 'Herd & calves', Icons.format_list_bulleted, '/herd'),
      if (canViewMilking) _buildNavItem(context, 'Milking log', Icons.water_drop_outlined, '/milking'),
      if (canViewHerd) _buildNavItem(context, 'Health & vaccination', Icons.medical_services_outlined, '/health'),
      if (canViewHerd) _buildNavItem(context, 'Breeding & calving', Icons.favorite_border, '/breeding'),
      if (canViewHerd) _buildNavItem(context, 'Feed & ration planning', Icons.grass_outlined, '/feed'),
      if (canViewCosting) _buildNavItem(context, 'Unit costing', Icons.calculate_outlined, '/costing'),
    ];
  }

  List<Widget> _buildMilkToMarketSection(BuildContext context, UserProfile? user) {
    final canViewBmc = user == null || user.isOwner || user.isManager || user.isBmcOperator || user.isQcStaff || user.isAuditor;
    final canViewProd = user == null || user.isOwner || user.isManager || user.isProductionOperator || user.isQcStaff || user.isAuditor;
    final canViewPack = user == null || user.isOwner || user.isManager || user.isProductionOperator || user.isAuditor;
    final canViewQc = user == null || user.isOwner || user.isManager || user.isBmcOperator || user.isQcStaff || user.isAuditor;
    final canViewMaterials = user == null || user.isOwner || user.isManager || user.isProductionOperator || user.isStorekeeper || user.isAuditor;
    final canViewElectricity = user == null || user.isOwner || user.isManager || user.isAccountant || user.isAuditor;
    final canViewSales = user == null || user.isOwner || user.isManager || user.isSalesStaff || user.isAccountant || user.isAuditor;

    return [
      const SizedBox(height: 8),
      _buildSectionHeader('MILK TO MARKET'),
      if (canViewBmc) _buildNavItem(context, 'BMC & milk intake', Icons.local_shipping_outlined, '/bmc'),
      if (canViewProd) _buildNavItem(context, 'Production batches', Icons.blender_outlined, '/batches'),
      if (canViewPack) _buildNavItem(context, 'Packaging', Icons.inventory_2_outlined, '/packaging'),
      if (canViewQc) _buildNavItem(context, 'Quality records', Icons.verified_outlined, '/quality'),
      if (canViewMaterials) _buildNavItem(context, 'Material issues', Icons.outbox_outlined, '/materials'),
      if (canViewElectricity) _buildNavItem(context, 'Electricity readings', Icons.bolt_outlined, '/electricity'),
      if (canViewSales) _buildNavItem(context, 'Orders & dispatch', Icons.assignment_outlined, '/orders'),
      if (canViewSales) _buildNavItem(context, 'Sales', Icons.point_of_sale_outlined, '/sales'),
      if (canViewSales) _buildNavItem(context, 'Customer payments', Icons.payments_outlined, '/payments'),
    ];
  }

  List<Widget> _buildBusinessSection(BuildContext context, UserProfile? user) {
    final canViewInventory = user == null || user.isOwner || user.isManager || user.isStorekeeper || user.isAccountant || user.isAuditor;
    final canViewBiogas = user == null || user.isOwner || user.isManager || user.isProductionOperator || user.isAuditor;
    final canViewWastage = user == null || user.isOwner || user.isManager || user.isStorekeeper || user.isAuditor;
    final canViewExpenses = user == null || user.isOwner || user.isAccountant || user.isAuditor;
    final canViewEmployees = user == null || user.isOwner || user.isHrAdmin || user.isAccountant || user.isAuditor;
    final canViewLicences = user == null || user.isOwner || user.isManager || user.isAuditor;
    final canViewReports = user == null || user.isOwner || user.isManager || user.isAccountant || user.isAuditor;
    final canViewSettings = user == null || user.isOwner || user.isManager;

    return [
      const SizedBox(height: 8),
      _buildSectionHeader('BUSINESS'),
      if (canViewInventory) _buildNavItem(context, 'Common inventory', Icons.warehouse_outlined, '/inventory'),
      if (canViewBiogas) _buildNavItem(context, 'Biogas fertiliser', Icons.eco_outlined, '/biogas'),
      if (canViewWastage) _buildNavItem(context, 'Wastage & losses', Icons.delete_sweep_outlined, '/wastage'),
      if (canViewExpenses) _buildNavItem(context, 'Costs & expenses', Icons.receipt_long_outlined, '/expenses'),
      if (canViewEmployees) _buildNavItem(context, 'Employees & payroll', Icons.people_outline, '/employees'),
      if (canViewLicences) _buildNavItem(context, 'FSSAI & licences', Icons.policy_outlined, '/licences'),
      if (canViewReports) _buildNavItem(context, 'Reports & exports', Icons.bar_chart_outlined, '/reports'),
      if (canViewSettings) _buildNavItem(context, 'Farm settings', Icons.settings_outlined, '/settings'),
    ];
  }

  Widget _buildLogoutFooter(BuildContext context, WidgetRef ref, UserProfile? user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x22FFFFFF), width: 1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to end your current session?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) {
              context.go('/login');
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red.shade300, size: 20),
              const SizedBox(width: 12),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.red.shade200,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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
