import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shareloop/controllers/auth_controller.dart';
import 'package:shareloop/controllers/item_controller.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/views/give_away/create_give_away_screen.dart';

Future<void> _pumpGive(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = AuthController();
  await tester.runAsync(() => auth.login('nimal@example.com', 'x'));

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => ItemController()),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
        home: const CreateGiveAwayScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the form with the condition defaulted to Good',
      (tester) async {
    await _pumpGive(tester);

    expect(find.text('Give an Item'), findsOneWidget);
    expect(find.text('Add photos of your item'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);
    expect(find.text('Select a category'), findsOneWidget);
    expect(find.text('Publish Item'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Good')),
      isSemantics(isButton: true, isSelected: true, label: 'Good'),
    );
  });

  testWidgets('prefills the location from the user profile', (tester) async {
    await _pumpGive(tester);

    final user = tester
        .element(find.byType(CreateGiveAwayScreen))
        .read<AuthController>()
        .currentUser!;
    expect(find.text(user.district), findsOneWidget);
    expect(find.text(user.city), findsOneWidget);
  });

  testWidgets('publishing an empty form shows field errors', (tester) async {
    await _pumpGive(tester);

    await tester.tap(find.text('Publish Item'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a title'), findsOneWidget);
    expect(find.text('Please add a short description'), findsOneWidget);
    expect(find.text('Please select a category'), findsOneWidget);
  });

  for (final size in const [Size(320, 568), Size(360, 800)]) {
    testWidgets('does not overflow at $size', (tester) async {
      await _pumpGive(tester, size: size);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  for (final code in const ['si', 'ta']) {
    testWidgets('does not overflow in $code at 320 wide', (tester) async {
      await _pumpGive(
        tester,
        size: const Size(320, 568),
        locale: Locale(code),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
