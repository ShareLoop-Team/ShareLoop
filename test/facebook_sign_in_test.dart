import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shareloop/controllers/auth_controller.dart';
import 'package:shareloop/core/errors/app_exception.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/core/routes/app_routes.dart';
import 'package:shareloop/models/email_code.dart';
import 'package:shareloop/models/user_model.dart';
import 'package:shareloop/services/facebook_auth_service.dart';
import 'package:shareloop/views/auth/complete_google_profile_screen.dart';
import 'package:shareloop/widgets/facebook/facebook_sign_in_button.dart';

/// "Continue with Facebook" on mock data, where the token is just the email.
void main() {
  test('an existing account signs straight in', () async {
    final auth = AuthController();
    final result = await auth.signInWithFacebook('nimal@example.com');
    expect(result, isA<UserModel>());
    expect(auth.currentUser?.email, 'nimal@example.com');
  });

  test('a new person is asked for their details, then gets an account',
      () async {
    final auth = AuthController();
    final result = await auth.signInWithFacebook('fb.first@example.com');
    expect(result, isA<GoogleSignUpNeeded>());
    expect((result! as GoogleSignUpNeeded).provider, SocialProvider.facebook);
    expect(auth.currentUser, isNull);

    final done = await auth.completeGoogleSignUp(
      result as GoogleSignUpNeeded,
      name: 'FB First',
      phone: '0771234567',
      district: 'Galle',
      city: '',
    );
    expect(done, isTrue);
    expect(auth.currentUser?.name, 'FB First');
    expect(auth.currentUser?.email, 'fb.first@example.com');
  });

  test('outside the web app the service explains it needs the web app',
      () async {
    expect(FacebookAuthService.instance.isSupported, isFalse);
    expect(
      FacebookAuthService.instance.signIn,
      throwsA(isA<AppException>()),
    );
  });

  Widget app(AuthController auth, Widget home) =>
      ChangeNotifierProvider<AuthController>.value(
        value: auth,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {AppRoutes.home: (_) => const Scaffold(body: Text('HOME'))},
          home: home,
        ),
      );

  testWidgets('without a Facebook App ID the button runs onUnavailable', (
    tester,
  ) async {
    var unavailable = 0;
    await tester.pumpWidget(app(
      AuthController(),
      Scaffold(
        body: FacebookSignInButton(
          label: 'Continue with Facebook',
          onUnavailable: () => unavailable++,
        ),
      ),
    ));
    await tester.tap(find.text('Continue with Facebook'));
    await tester.pump();
    expect(unavailable, 1);
  });

  testWidgets('finish sign-up screen mentions Facebook', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(
      AuthController(),
      const CompleteGoogleProfileScreen(
        pending: GoogleSignUpNeeded(
          idToken: 'fb.user@example.com',
          email: 'fb.user@example.com',
          name: 'FB User',
          provider: SocialProvider.facebook,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('signing up with Facebook as fb.user@example.com'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'FB User'), findsOneWidget);
  });
}
