import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../app_drawer.dart';
import 'app_responsive.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final String currentRoute;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentRoute,
    this.actions,
    this.floatingActionButton,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = AppResponsive.isExpanded(context);

    if (isExpanded) {
      // Tablet & Desktop: Split-screen shell with persistent deep-green navigation sidebar
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // Persistent Sidebar
            SizedBox(
              width: 260,
              child: AppDrawer(
                currentRoute: currentRoute,
                isPersistent: true,
              ),
            ),
            const VerticalDivider(width: 1, color: AppColors.borderSubtle),
            // Main content area
            Expanded(
              child: Scaffold(
                backgroundColor: AppColors.background,
                appBar: AppBar(
                  title: Text(title),
                  automaticallyImplyLeading: false,
                  actions: [
                    ...?actions,
                    const SizedBox(width: 8),
                    _buildUserAvatar(),
                    const SizedBox(width: 16),
                  ],
                  bottom: bottom,
                ),
                body: body,
                floatingActionButton: floatingActionButton,
              ),
            ),
          ],
        ),
      );
    }

    // Phone & Compact Tablet: Standard App Bar with Hamburger Drawer
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...?actions,
          const SizedBox(width: 4),
          _buildUserAvatar(),
          const SizedBox(width: 12),
        ],
        bottom: bottom,
      ),
      drawer: AppDrawer(currentRoute: currentRoute),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildUserAvatar() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {},
      child: const CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.primary50,
        child: Text(
          'KD',
          style: TextStyle(
            color: AppColors.primary800,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
