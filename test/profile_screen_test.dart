import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shareloop/controllers/auth_controller.dart';
import 'package:shareloop/controllers/badge_controller.dart';
import 'package:shareloop/controllers/language_controller.dart';
import 'package:shareloop/controllers/profile_controller.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/core/theme/app_theme.dart';
import 'package:shareloop/core/routes/app_routes.dart';
import 'package:shareloop/views/profile/my_donations_screen.dart';
import 'package:shareloop/views/profile/profile_screen.dart';

Future<LanguageController> _pumpProfile(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  String languageCode = 'en',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = AuthController();
  await tester.runAsync(() => auth.login('nimal@example.com', 'x'));
  final language = LanguageController()..setLanguage(languageCode);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: language),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => BadgeController()),
      ],
      child: Consumer<LanguageController>(
        builder: (context, languageController, _) => MaterialApp(
          theme: AppTheme.lightTheme,
          locale: languageController.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
          home: const Scaffold(body: ProfileScreen()),
          onGenerateRoute: (settings) => switch (settings.name) {
            AppRoutes.myDonations =>
              MaterialPageRoute(builder: (_) => const MyDonationsScreen()),
            _ => null,
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return language;
}

void main() {
  testWidgets('shows identity, badge and stats', (tester) async {
    await _pumpProfile(tester);

    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Nimal Perera'), findsOneWidget);
    expect(find.text('nimal@example.com'), findsOneWidget);
    expect(find.text('Active Contributor · Silver'), findsOneWidget);
    expect(find.text('Items given'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Next badge: Gold'), findsOneWidget);
    expect(find.text('12 of 25 items'), findsOneWidget);
  });

  testWidgets('My Donations opens a page of the user\'s posts',
      (tester) async {
    await _pumpProfile(tester);

    await tester.scrollUntilVisible(find.text('My Donations'), 200);
    await tester.tap(find.text('My Donations'));
    await tester.pumpAndSettle();

    expect(find.byType(MyDonationsScreen), findsOneWidget);
    expect(find.text('Items you have given away'), findsOneWidget);
    expect(find.text('White Cotton T-Shirt'), findsOneWidget);
  });

  testWidgets('language picker switches the app language', (tester) async {
    final language = await _pumpProfile(tester);

    await tester.scrollUntilVisible(find.text('Language'), 200);
    await tester.ensureVisible(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sinhala (සිංහල)'));
    await tester.pumpAndSettle();

    expect(language.locale.languageCode, 'si');
    expect(find.text('භාෂාව'), findsOneWidget);
    expect(find.text('Sinhala (සිංහල)'), findsOneWidget);
  });

  testWidgets('sign out asks for confirmation first', (tester) async {
    await _pumpProfile(tester);

    await tester.scrollUntilVisible(find.text('Sign Out'), 200);
    await tester.ensureVisible(find.text('Sign Out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out of ShareLoop?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out of ShareLoop?'), findsNothing);
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });

  for (final code in const ['en', 'si', 'ta']) {
    testWidgets('does not overflow in $code at 320 wide', (tester) async {
      await _pumpProfile(
        tester,
        size: const Size(320, 568),
        languageCode: code,
      );
      await tester.scrollUntilVisible(find.byType(OutlinedButton).last, 300);
      expect(tester.takeException(), isNull);
    });
  }
}
