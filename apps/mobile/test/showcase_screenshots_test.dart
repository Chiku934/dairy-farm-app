import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dairy_mobile/core/theme/app_theme.dart';
import 'package:dairy_mobile/features/showcase/presentation/ui_showcase_screen.dart';

void main() {
  testWidgets('Capture Phone Screenshot (400x800)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const UIShowcaseScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(UIShowcaseScreen),
      matchesGoldenFile('goldens/showcase_phone.png'),
    );
  });

  testWidgets('Capture Tablet Screenshot (1024x768)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const UIShowcaseScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(UIShowcaseScreen),
      matchesGoldenFile('goldens/showcase_tablet.png'),
    );
  });
}
