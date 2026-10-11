import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dairy_mobile/main.dart';
import 'package:dairy_mobile/core/widgets/kpi_card.dart';

void main() {
  testWidgets('DairyFarmMobileApp mounts and displays Overview screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DairyFarmMobileApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Overview title and core elements render
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Record milking'), findsOneWidget);
    expect(find.text('MILK RECORDED'), findsOneWidget);
    expect(find.text('SALES REVENUE'), findsOneWidget);
  });

  testWidgets('KpiCard renders title, value and subtitle correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KpiCard(
            title: 'Test Metric',
            value: '500 L',
            subtitle: 'Target reached',
          ),
        ),
      ),
    );

    expect(find.text('TEST METRIC'), findsOneWidget);
    expect(find.text('500 L'), findsOneWidget);
    expect(find.text('Target reached'), findsOneWidget);
  });
}
