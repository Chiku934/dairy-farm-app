import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dairy_mobile/core/theme/app_theme.dart';
import 'package:dairy_mobile/features/auth/domain/user_session.dart';
import 'package:dairy_mobile/features/auth/presentation/auth_provider.dart';
import 'package:dairy_mobile/features/auth/presentation/login_screen.dart';
import 'package:dairy_mobile/core/widgets/app_drawer.dart';

void main() {
  group('Phase 4: Flutter Authentication & Role-Aware Shell Tests', () {
    testWidgets('LoginScreen renders email, password inputs, and quick-fill demo chips', (tester) async {
      tester.view.physicalSize = const Size(1024, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kaivalya Dairy'), findsOneWidget);
      expect(find.text('Sign In to Farm App'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Owner / Admin'), findsOneWidget);
      expect(find.text('Auditor (Read-Only)'), findsOneWidget);
    });

    testWidgets('LoginScreen shows validation errors for empty fields', (tester) async {
      tester.view.physicalSize = const Size(1024, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clear the text fields
      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.enterText(find.byType(TextFormField).last, '');
      await tester.tap(find.text('Sign In to Farm App'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('Quick-fill preset chips populate form fields', (tester) async {
      tester.view.physicalSize = const Size(1024, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Auditor (Read-Only)'));
      await tester.tap(find.text('Auditor (Read-Only)'));
      await tester.pumpAndSettle();

      expect(find.text('auditor@dairyfarm.local'), findsOneWidget);
    });

    testWidgets('AppDrawer displays user profile and role badge for Super Admin', (tester) async {
      tester.view.physicalSize = const Size(1024, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final adminProfile = UserProfile(
        id: 'usr-dev-admin',
        email: 'admin@dairyfarm.local',
        fullName: 'Arjun Patel',
        roles: ['FARM_OWNER'],
        permissions: ['*'],
      );

      final adminSession = UserSession(
        accessToken: 'mock-token',
        refreshToken: 'mock-refresh',
        expiresInSeconds: 900,
        user: adminProfile,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => MockAuthNotifier(Authenticated(adminSession))),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              drawer: AppDrawer(currentRoute: '/'),
            ),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Arjun Patel'), findsOneWidget);
      expect(find.text('admin@dairyfarm.local'), findsOneWidget);
      expect(find.text('Farm Owner / Admin'), findsOneWidget);
      expect(find.text('Herd & calves'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('AppDrawer filters out restricted business modules for Animal Care staff', (tester) async {
      tester.view.physicalSize = const Size(1024, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final animalCareProfile = UserProfile(
        id: 'usr-dev-animal',
        email: 'animal@dairyfarm.local',
        fullName: 'Raju Gope',
        roles: ['ANIMAL_CARE'],
        permissions: ['animals:read', 'animals:write', 'milking:read', 'milking:write'],
      );

      final animalCareSession = UserSession(
        accessToken: 'mock-token',
        refreshToken: 'mock-refresh',
        expiresInSeconds: 900,
        user: animalCareProfile,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => MockAuthNotifier(Authenticated(animalCareSession))),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              drawer: AppDrawer(currentRoute: '/'),
            ),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Raju Gope'), findsOneWidget);
      expect(find.text('Herd / Animal Care'), findsOneWidget);
      expect(find.text('Herd & calves'), findsOneWidget);
      expect(find.text('Milking log'), findsOneWidget);

      // Restricted financial & management modules must be hidden
      expect(find.text('Costs & expenses'), findsNothing);
      expect(find.text('Farm settings'), findsNothing);
    });
  });
}

class MockAuthNotifier extends AuthNotifier {
  final AuthState initial;
  MockAuthNotifier(this.initial);

  @override
  AuthState build() => initial;
}
