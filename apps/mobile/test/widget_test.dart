import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dairy_mobile/main.dart';
import 'package:dairy_mobile/core/theme/app_theme.dart';
import 'package:dairy_mobile/core/widgets/buttons/app_button.dart';
import 'package:dairy_mobile/core/widgets/cards/app_kpi_card.dart';
import 'package:dairy_mobile/core/widgets/chips/app_status_chip.dart';
import 'package:dairy_mobile/core/widgets/inputs/app_number_input.dart';
import 'package:dairy_mobile/core/widgets/states/app_state_views.dart';
import 'package:dairy_mobile/core/widgets/tables/app_data_table.dart';
import 'package:dairy_mobile/features/showcase/presentation/ui_showcase_screen.dart';

void main() {
  testWidgets('DairyFarmMobileApp mounts and displays Overview screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DairyFarmMobileApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Record milking'), findsOneWidget);
    expect(find.text('MILK RECORDED'), findsOneWidget);
  });

  testWidgets('AppButton renders variants, states, and fires callbacks', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Column(
            children: [
              AppButton.primary(
                label: 'Save Record',
                onPressed: () => tapped = true,
              ),
              const AppButton.destructive(
                label: 'Delete Record',
                onPressed: null,
              ),
              const AppButton.outline(
                label: 'Loading Button',
                isLoading: true,
                onPressed: null,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Save Record'), findsOneWidget);
    expect(find.text('Delete Record'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('Save Record'));
    expect(tapped, isTrue);
  });

  testWidgets('AppKpiCard renders metrics, labels and trend badge', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: AppKpiCard(
            title: 'Milk Recorded',
            value: '25.0 L',
            subtitle: 'Daily yield',
            trendPercent: 4.5,
          ),
        ),
      ),
    );

    expect(find.text('MILK RECORDED'), findsOneWidget);
    expect(find.text('25.0 L'), findsOneWidget);
    expect(find.text('+4.5%'), findsOneWidget);
  });

  testWidgets('AppStatusChip renders success, warning and danger badges', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Column(
            children: [
              AppStatusChip.success(label: 'Lactating'),
              AppStatusChip.warning(label: 'Pregnant'),
              AppStatusChip.danger(label: 'Withheld'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Lactating'), findsOneWidget);
    expect(find.text('Pregnant'), findsOneWidget);
    expect(find.text('Withheld'), findsOneWidget);
  });

  testWidgets('AppNumberInputField increments and decrements value', (WidgetTester tester) async {
    double currentValue = 10.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: AppNumberInputField(
                label: 'Daily Yield',
                value: currentValue,
                step: 1.0,
                unitSuffix: 'L',
                onChanged: (val) => setState(() => currentValue = val),
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('Daily Yield'), findsOneWidget);
    expect(find.text('10.0'), findsOneWidget);
    expect(find.text('L'), findsOneWidget);

    // Tap plus button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(currentValue, 11.0);

    // Tap minus button
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pumpAndSettle();
    expect(currentValue, 10.0);
  });

  testWidgets('AppDataTable renders columns, rows, and pagination', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppDataTable(
            currentPage: 1,
            totalPages: 3,
            totalItems: 12,
            pageSize: 4,
            columns: const [
              AppTableColumn(title: 'Tag', width: 100),
              AppTableColumn(title: 'Breed', width: 120),
            ],
            rows: const [
              [Text('COW-01'), Text('Jersey')],
              [Text('COW-02'), Text('Holstein')],
            ],
          ),
        ),
      ),
    );

    expect(find.text('TAG'), findsOneWidget);
    expect(find.text('BREED'), findsOneWidget);
    expect(find.text('COW-01'), findsOneWidget);
    expect(find.text('Jersey'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('AppEmptyState and AppErrorState render correctly', (WidgetTester tester) async {
    bool retried = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Column(
            children: [
              const AppEmptyState(
                title: 'No Animals',
                description: 'Add a new animal to herd registry.',
              ),
              AppErrorState(
                title: 'Network Offline',
                onRetry: () => retried = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('No Animals'), findsOneWidget);
    expect(find.text('Network Offline'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('UIShowcaseScreen mounts on Phone screen size (400x800)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const UIShowcaseScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('UI & Design System Showcase'), findsOneWidget);
    expect(find.text('Kaivalya Dairy UI/UX Design System'), findsOneWidget);
    expect(find.text('1. Color Palette & Surface Tokens'), findsOneWidget);
  });

  testWidgets('UIShowcaseScreen mounts on Tablet screen size (1024x768)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const UIShowcaseScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('UI & Design System Showcase'), findsOneWidget);
    expect(find.text('Kaivalya Dairy'), findsOneWidget);
    expect(find.text('Dandiri · Odisha'), findsOneWidget);
  });
}
