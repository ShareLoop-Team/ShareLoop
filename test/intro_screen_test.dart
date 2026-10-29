import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/core/routes/app_routes.dart';
import 'package:shareloop/views/onboarding/intro_screen.dart';

/// Pumps the intro with a stand-in for the welcome screen it continues to.
Future<void> _openIntro(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const IntroScreen(),
      onGenerateRoute: (settings) => settings.name == AppRoutes.onboarding
          ? MaterialPageRoute(builder: (_) => const Text('welcome'))
          : null,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts on the first page with Skip and Next', (tester) async {
    await _openIntro(tester);

    expect(find.text("Give what you don't need"), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.bySemanticsLabel('Page 1 of 2'), findsOneWidget);
  });

  testWidgets('Skip goes to the welcome screen', (tester) async {
    await _openIntro(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('welcome'), findsOneWidget);
    expect(find.byType(IntroScreen), findsNothing);
  });

  testWidgets('Next shows the second page, then Next again finishes', (
    tester,
  ) async {
    await _openIntro(tester);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Get what you do'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.bySemanticsLabel('Page 2 of 2'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('welcome'), findsOneWidget);
  });

  testWidgets('swiping changes the page', (tester) async {
    await _openIntro(tester);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Get what you do'), findsOneWidget);
  });

  for (final locale in const [Locale('en'), Locale('si'), Locale('ta')]) {
    for (final size in const [Size(320, 480), Size(360, 800)]) {
      testWidgets('does not overflow in ${locale.languageCode} at $size', (
        tester,
      ) async {
        await _openIntro(tester, size: size, locale: locale);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
