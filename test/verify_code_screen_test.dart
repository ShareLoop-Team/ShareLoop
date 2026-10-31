import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shareloop/controllers/auth_controller.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/core/routes/app_routes.dart';
import 'package:shareloop/models/email_code.dart';
import 'package:shareloop/services/mock_data_service.dart';
import 'package:shareloop/views/auth/verify_code_screen.dart';

/// The "enter the emailed code" screen on mock data (code is 123456).
void main() {
  late AuthController auth;

  Widget app(VerifyCodeArgs args) {
    return ChangeNotifierProvider<AuthController>.value(
      value: auth,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {AppRoutes.home: (_) => const Scaffold(body: Text('HOME'))},
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VerifyCodeScreen(args: args),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester, VerifyCodeArgs args) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(args));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    await tester.enterText(find.byKey(const Key('verify-code-field')), code);
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    final button = find.widgetWithText(ElevatedButton, label);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  setUp(() {
    auth = AuthController();
    MockDataService.instance.currentUserId = null;
  });

  testWidgets('registration: wrong code is refused, right code signs in', (
    tester,
  ) async {
    const details = PendingRegistration(
      name: 'Code Tester',
      email: 'code.tester@example.com',
      password: 'secret123',
      phone: '0771234567',
      district: 'Kandy',
      city: 'Peradeniya',
    );
    await open(
      tester,
      const VerifyCodeArgs(
        ticket: EmailCodeTicket(
          email: 'code.tester@example.com',
          purpose: EmailCodePurpose.register,
          debugCode: '123456',
        ),
        registration: details,
      ),
    );

    expect(find.text('Confirm your email'), findsOneWidget);
    expect(find.textContaining('code.tester@example.com'), findsOneWidget);
    expect(find.textContaining('your code is 123456'), findsOneWidget);
    expect(find.text('Send a new code in 60s'), findsOneWidget);

    await tapButton(tester, 'Create Account');
    expect(find.text('Enter the 6-digit code'), findsOneWidget);

    await enterCode(tester, '000000');
    await tapButton(tester, 'Create Account');
    expect(find.text("That code isn't right."), findsOneWidget);

    await enterCode(tester, '123456');
    await tapButton(tester, 'Create Account');
    expect(find.text('HOME'), findsOneWidget);
    expect(auth.currentUser?.email, 'code.tester@example.com');
  });

  testWidgets('only sign-up promises the code was emailed', (tester) async {
    await open(
      tester,
      const VerifyCodeArgs(
        ticket: EmailCodeTicket(
          email: 'someone@example.com',
          purpose: EmailCodePurpose.register,
        ),
      ),
    );
    expect(find.textContaining('We emailed a 6-digit code'), findsOneWidget);

    for (final purpose in [EmailCodePurpose.login, EmailCodePurpose.reset]) {
      await tester.pumpWidget(const SizedBox()); // drop the previous screen
      await open(
        tester,
        VerifyCodeArgs(
          ticket: EmailCodeTicket(email: 'someone@example.com', purpose: purpose),
        ),
      );
      expect(
        find.textContaining('If an account exists for someone@example.com'),
        findsOneWidget,
      );
      expect(find.textContaining('We emailed a 6-digit code'), findsNothing);
    }
  });

  testWidgets('sign in with a code', (tester) async {
    await open(
      tester,
      const VerifyCodeArgs(
        ticket: EmailCodeTicket(
          email: 'nimal@example.com',
          purpose: EmailCodePurpose.login,
        ),
      ),
    );
    expect(find.text('Sign in with a code'), findsOneWidget);
    expect(find.textContaining('your code is'), findsNothing);

    await enterCode(tester, '123456');
    await tapButton(tester, 'Sign In');
    expect(find.text('HOME'), findsOneWidget);
    expect(auth.currentUser?.email, 'nimal@example.com');
  });

  testWidgets('reset: checks the new password, then goes back', (
    tester,
  ) async {
    await open(
      tester,
      const VerifyCodeArgs(
        ticket: EmailCodeTicket(
          email: 'nimal@example.com',
          purpose: EmailCodePurpose.reset,
        ),
      ),
    );
    expect(find.text('Reset your password'), findsOneWidget);

    await enterCode(tester, '123456');
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'newpass1');
    await tester.enterText(fields.at(2), 'different');
    await tapButton(tester, 'Change Password');
    expect(find.text('Passwords do not match'), findsOneWidget);

    await tester.enterText(fields.at(2), 'newpass1');
    await tapButton(tester, 'Change Password');
    expect(find.text('open'), findsOneWidget);
    expect(
      find.text('Password changed. Sign in with your new password.'),
      findsOneWidget,
    );
  });

  testWidgets('resend unlocks after the countdown', (tester) async {
    await open(
      tester,
      const VerifyCodeArgs(
        ticket: EmailCodeTicket(
          email: 'nimal@example.com',
          purpose: EmailCodePurpose.login,
          resendInSeconds: 2,
        ),
      ),
    );
    expect(find.text('Send a new code in 2s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Send a new code'), findsOneWidget);

    await tester.tap(find.text('Send a new code'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('A new code is on its way.'), findsOneWidget);
    expect(find.text('Send a new code in 60s'), findsOneWidget);
    // Let the countdown timer finish so the test ends cleanly.
    await tester.pump(const Duration(seconds: 61));
  });
}
