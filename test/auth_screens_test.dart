import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shareloop/controllers/auth_controller.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/core/theme/app_theme.dart';
import 'package:shareloop/core/theme/sl_tokens.dart';
import 'package:shareloop/views/auth/login_screen.dart';
import 'package:shareloop/views/auth/register_screen.dart';
import 'package:shareloop/widgets/sl/sl_button.dart';

Future<AuthController> _pump(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(390, 844),
  Locale locale = const Locale('en'),
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = AuthController();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: auth,
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  group('Login', () {
    testWidgets('shows the email and password form', (tester) async {
      await _pump(tester, const LoginScreen());

      expect(find.text('Welcome back!'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.widgetWithText(SLButton, 'Sign In'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('Google and Facebook say they are not available yet', (
      tester,
    ) async {
      final auth = await _pump(tester, const LoginScreen());

      for (final provider in ['Google', 'Facebook']) {
        final button = find.text(provider);
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(find.text("Social sign-in isn't available yet."), findsOneWidget);
        expect(auth.currentUser, isNull);
        ScaffoldMessenger.of(
          tester.element(find.byType(LoginScreen)),
        ).removeCurrentSnackBar();
        await tester.pumpAndSettle();
      }
      expect(find.bySemanticsLabel('Sign in with Google'), findsOneWidget);
    });

    testWidgets('empty fields show errors', (tester) async {
      await _pump(tester, const LoginScreen());

      await tester.tap(find.widgetWithText(SLButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('a failed sign-in shows the error', (tester) async {
      await _pump(tester, const LoginScreen());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your Email'),
        'nobody@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter Password'),
        'secret1',
      );
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(SLButton, 'Sign In'));
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('follows the dark theme', (tester) async {
      await _pump(tester, const LoginScreen(), theme: AppTheme.darkTheme);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, SLColors.dark.ground);
    });

    for (final code in const ['en', 'si', 'ta']) {
      for (final dark in const [false, true]) {
        testWidgets(
          'does not overflow in $code at 320x480 '
          '(${dark ? 'dark' : 'light'})',
          (tester) async {
            await _pump(
              tester,
              const LoginScreen(),
              size: const Size(320, 480),
              locale: Locale(code),
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            );
            final button = find.byType(SLButton);
            await tester.ensureVisible(button);
            await tester.pumpAndSettle();
            await tester.tap(button);
            await tester.pumpAndSettle();
            final l10n = AppLocalizations.of(
              tester.element(find.byType(LoginScreen)),
            );
            expect(find.text(l10n.loginEmailRequired), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });

  group('Register', () {
    testWidgets('Google sign-up says it is not available yet', (
      tester,
    ) async {
      final auth = await _pump(tester, const RegisterScreen());

      expect(find.text('Create account'), findsOneWidget);
      final google = find.text('Google');
      await tester.ensureVisible(google);
      await tester.pumpAndSettle();
      await tester.tap(google);
      await tester.pumpAndSettle();
      expect(find.text("Social sign-in isn't available yet."), findsOneWidget);
      expect(auth.currentUser, isNull);
      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('city waits for a district, then lists its cities', (
      tester,
    ) async {
      await _pump(tester, const RegisterScreen());

      expect(find.text('Select a district first'), findsOneWidget);

      final dropdowns = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(dropdowns.first);
      await tester.pumpAndSettle();
      await tester.tap(dropdowns.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Colombo').last);
      await tester.pumpAndSettle();

      expect(find.text('Select a district first'), findsNothing);
      expect(find.text('Select your city or town'), findsOneWidget);
      await tester.ensureVisible(dropdowns.last);
      await tester.pumpAndSettle();
      await tester.tap(dropdowns.last);
      await tester.pumpAndSettle();
      expect(find.text('Battaramulla'), findsWidgets);
    });

    testWidgets('follows the dark theme', (tester) async {
      await _pump(tester, const RegisterScreen(), theme: AppTheme.darkTheme);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, SLColors.dark.ground);
    });

    for (final code in const ['en', 'si', 'ta']) {
      for (final dark in const [false, true]) {
        testWidgets(
          'does not overflow in $code at 320x480 '
          '(${dark ? 'dark' : 'light'})',
          (tester) async {
            await _pump(
              tester,
              const RegisterScreen(),
              size: const Size(320, 480),
              locale: Locale(code),
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            );
            final button = find.byType(SLButton);
            await tester.ensureVisible(button);
            await tester.pumpAndSettle();
            await tester.tap(button);
            await tester.pumpAndSettle();
            final l10n = AppLocalizations.of(
              tester.element(find.byType(RegisterScreen)),
            );
            expect(find.text(l10n.registerNameRequired), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}
