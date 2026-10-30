import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shareloop/controllers/language_controller.dart';
import 'package:shareloop/core/constants/app_colors.dart';
import 'package:shareloop/main.dart';
import 'package:shareloop/views/auth/login_screen.dart';
import 'package:shareloop/views/onboarding/intro_screen.dart';
import 'package:shareloop/views/onboarding/onboarding_screen.dart';
import 'package:shareloop/views/splash/splash_screen.dart';

Future<void> _openOnboarding(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const ShareLoopApp());
  await tester.pump(const Duration(milliseconds: 50));
  expect(find.byType(SplashScreen), findsOneWidget);

  // Splash holds for its minimum duration, then replaces itself with the
  // intro pages; Skip continues to the welcome screen.
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
  expect(find.byType(IntroScreen), findsOneWidget);
  await tester.tap(find.text('Skip'));
  await tester.pumpAndSettle();
}

Future<void> _openLogin(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  await _openOnboarding(tester, size: size);
  await tester.ensureVisible(find.text('Get started'));
  await tester.tap(find.text('Get started'));
  await tester.pumpAndSettle();
  expect(find.byType(LoginScreen), findsOneWidget);
}

void main() {
  testWidgets('Splash and intro continue to the onboarding screen', (
    tester,
  ) async {
    await _openOnboarding(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.bySemanticsLabel('ShareLoop'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Log in'), findsNothing);
    expect(find.text('Register'), findsNothing);
  });

  testWidgets('Get started opens the login screen and back returns', (
    tester,
  ) async {
    await _openOnboarding(tester);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    // The design has no app bar, so go back with the system back action.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('Keeps brand light colors when the device is in dark mode', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _openOnboarding(tester);

    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, AppColors.canvas);
  });

  testWidgets('Follows the app language', (tester) async {
    await _openOnboarding(tester);

    final context = tester.element(find.byType(OnboardingScreen));
    Provider.of<LanguageController>(context, listen: false).setLanguage('si');
    await tester.pumpAndSettle();

    expect(find.text('අරඹමු'), findsOneWidget);
  });

  for (final size in const [
    Size(320, 480),
    Size(360, 800),
    Size(1080, 2400),
  ]) {
    testWidgets('does not overflow at $size', (tester) async {
      await _openOnboarding(tester, size: size);
      expect(tester.takeException(), isNull);
    });
  }

  group('Login screen', () {
    Future<void> openLogin(
      WidgetTester tester, {
      Size size = const Size(390, 844),
    }) async {
      await _openLogin(tester, size: size);
    }

    testWidgets('toggles password visibility', (tester) async {
      await openLogin(tester);

      bool obscured() => tester
          .widget<EditableText>(
            find.descendant(
              of: find.widgetWithText(TextFormField, 'Enter Password'),
              matching: find.byType(EditableText),
            ),
          )
          .obscureText;

      expect(obscured(), isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(obscured(), isFalse);
    });

    testWidgets('Create Account opens registration', (tester) async {
      await openLogin(tester);

      await tester.ensureVisible(find.text('Create Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();
      expect(find.text('Create account'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    for (final size in const [Size(320, 480), Size(360, 800)]) {
      testWidgets('does not overflow at $size', (tester) async {
        await openLogin(tester, size: size);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Register screen', () {
    Future<void> openRegister(
      WidgetTester tester, {
      Size size = const Size(390, 844),
    }) async {
      // New users reach registration through login's Create Account link.
      await _openLogin(tester, size: size);
      await tester.ensureVisible(find.text('Create Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();
      expect(find.text('Create account'), findsOneWidget);
    }

    Future<void> tapRegisterButton(WidgetTester tester) async {
      final button = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    testWidgets('shows errors for an empty form', (tester) async {
      await openRegister(tester);
      await tapRegisterButton(tester);

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Please select your district'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(
        find.text('Please accept the Terms and Privacy Policy'),
        findsOneWidget,
      );
    });

    testWidgets('ticking the terms box clears its error', (tester) async {
      await openRegister(tester);
      await tapRegisterButton(tester);
      const error = 'Please accept the Terms and Privacy Policy';
      expect(find.text(error), findsOneWidget);

      final checkbox = find.byType(Checkbox);
      await tester.ensureVisible(checkbox);
      await tester.pumpAndSettle();
      await tester.tap(checkbox);
      await tapRegisterButton(tester);
      expect(find.text(error), findsNothing);
    });

    testWidgets('rejects mismatched passwords', (tester) async {
      await openRegister(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Create a password'),
        'secret1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Re-enter your password'),
        'secret2',
      );
      await tapRegisterButton(tester);

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Sign In opens the login screen', (tester) async {
      await openRegister(tester);
      final signIn = find.text('Sign In');
      await tester.ensureVisible(signIn);
      await tester.pumpAndSettle();
      await tester.tap(signIn);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    for (final size in const [Size(320, 480), Size(360, 800)]) {
      testWidgets('does not overflow at $size', (tester) async {
        await openRegister(tester, size: size);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
