import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/auth_provider.dart';

class DashboardQuickActions extends ConsumerWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).session;
    final isAuditor = session?.isAuditor ?? false;

    // Read-only Auditors do not have write action buttons
    if (isAuditor) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: const Row(
          children: [
            Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF1D4ED8)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Auditor Mode Active: Read-only access enabled across all records.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final actions = <_ActionItem>[];

    if (session == null || session.hasPermission('milking:write')) {
      actions.add(_ActionItem(
        label: 'Log Milking',
        icon: Icons.water_drop_outlined,
        onTap: () => _showComingSoon(context, 'Milking Log entry form'),
      ));
    }

    if (session == null || session.hasPermission('bmc:write')) {
      actions.add(_ActionItem(
        label: 'BMC Intake',
        icon: Icons.local_drink_outlined,
        onTap: () => _showComingSoon(context, 'BMC Intake entry form'),
      ));
    }

    if (session == null || session.hasPermission('animals:write')) {
      actions.add(_ActionItem(
        label: 'Add Cattle',
        icon: Icons.pets_outlined,
        onTap: () => context.go('/herd'),
      ));
    }

    if (session == null || session.hasPermission('finance:write')) {
      actions.add(_ActionItem(
        label: 'Record Expense',
        icon: Icons.receipt_long_outlined,
        onTap: () => _showComingSoon(context, 'Operating Expense form'),
      ));
    }

    if (session == null || session.hasPermission('sales:write')) {
      actions.add(_ActionItem(
        label: 'Record Sale',
        icon: Icons.local_shipping_outlined,
        onTap: () => _showComingSoon(context, 'Sales Dispatch form'),
      ));
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Operations',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: actions.map((act) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ActionChip(
                  avatar: Icon(act.icon, size: 16, color: AppColors.primary700),
                  label: Text(
                    act.label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary800,
                    ),
                  ),
                  backgroundColor: AppColors.primary50,
                  side: const BorderSide(color: Color(0xFFBBF7D0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: act.onTap,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title is ready for module integration'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  _ActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}
