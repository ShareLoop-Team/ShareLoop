import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shareloop/controllers/auth_controller.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/core/routes/app_routes.dart';
import 'package:shareloop/models/email_code.dart';
import 'package:shareloop/models/user_model.dart';
import 'package:shareloop/views/auth/complete_google_profile_screen.dart';

/// "Sign in with Google" on mock data, where the ID token is just the email.
void main() {
  test('an existing account signs straight in', () async {
    final auth = AuthController();
    final result = await auth.signInWithGoogle('nimal@example.com');
    expect(result, isA<UserModel>());
    expect(auth.currentUser?.email, 'nimal@example.com');
  });

  test('a new person is asked for their details first', () async {
    final auth = AuthController();
    final result = await auth.signInWithGoogle('first.timer@gmail.com');
    expect(result, isA<GoogleSignUpNeeded>());
    expect(auth.currentUser, isNull);

    final done = await auth.completeGoogleSignUp(
      result! as GoogleSignUpNeeded,
      name: 'First Timer',
      phone: '0771234567',
      district: 'Galle',
      city: '',
    );
    expect(done, isTrue);
    expect(auth.currentUser?.name, 'First Timer');
  });

  testWidgets('finish sign-up screen checks the form, then goes home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final auth = AuthController();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: auth,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {AppRoutes.home: (_) => const Scaffold(body: Text('HOME'))},
          home: const CompleteGoogleProfileScreen(
            pending: GoogleSignUpNeeded(
              idToken: 'google.user@gmail.com',
              email: 'google.user@gmail.com',
              name: 'Google User',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Almost there'), findsOneWidget);
    expect(find.textContaining('google.user@gmail.com'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Google User'), findsOneWidget);

    final button = find.widgetWithText(ElevatedButton, 'Finish Sign-up');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Phone number is required'), findsOneWidget);
    expect(find.text('Please select your district'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '0771234567');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kandy').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(auth.currentUser?.email, 'google.user@gmail.com');
  });
}
