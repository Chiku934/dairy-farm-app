import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

enum DeviceScreenType {
  compact, // Phone (< 600)
  medium,  // Tablet portrait (600 - 900)
  expanded // Tablet landscape / Desktop (> 900)
}

class AppResponsive {
  static const double compactBreakpoint = 600.0;
  static const double mediumBreakpoint = 900.0;
  static const double maxContentWidth = 1200.0;

  static DeviceScreenType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < compactBreakpoint) {
      return DeviceScreenType.compact;
    } else if (width < mediumBreakpoint) {
      return DeviceScreenType.medium;
    } else {
      return DeviceScreenType.expanded;
    }
  }

  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < compactBreakpoint;

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= compactBreakpoint && width < mediumBreakpoint;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.of(context).size.width >= mediumBreakpoint;
}

class AppResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const AppResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = AppResponsive.maxContentWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = AppResponsive.isCompact(context);
    final defaultPadding = isCompact
        ? AppSpacing.screenPaddingMobile
        : AppSpacing.screenPaddingTablet;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? defaultPadding,
          child: child,
        ),
      ),
    );
  }
}

class AppResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int compactColumns;
  final int mediumColumns;
  final int expandedColumns;
  final double childAspectRatio;

  const AppResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 12.0,
    this.runSpacing = 12.0,
    this.compactColumns = 2,
    this.mediumColumns = 3,
    this.expandedColumns = 4,
    this.childAspectRatio = 1.3,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = AppResponsive.getDeviceType(context);

    int columns;
    switch (deviceType) {
      case DeviceScreenType.compact:
        // On very small phones (< 360dp), fallback to 1 column if requested or 2
        final width = MediaQuery.of(context).size.width;
        columns = width < 360 ? 1 : compactColumns;
        break;
      case DeviceScreenType.medium:
        columns = mediumColumns;
        break;
      case DeviceScreenType.expanded:
        columns = expandedColumns;
        break;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) => children[index],
    );
  }
}
