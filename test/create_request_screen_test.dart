import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shareloop/controllers/auth_controller.dart';
import 'package:shareloop/controllers/item_controller.dart';
import 'package:shareloop/controllers/request_controller.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/views/requests/create_request_screen.dart';
import 'package:shareloop/widgets/sl/sl_button.dart';

Future<RequestController> _pumpRequest(
  WidgetTester tester, {
  String? postId,
  Size size = const Size(390, 844),
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = AuthController();
  final items = ItemController();
  final requests = RequestController();
  await tester.runAsync(() async {
    await auth.login('nimal@example.com', 'x');
    await items.loadPosts();
  });

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: items),
        ChangeNotifierProvider.value(value: requests),
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
        home: CreateRequestScreen(postId: postId),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return requests;
}

Finder _field(String hint) => find.ancestor(
      of: find.text(hint),
      matching: find.byType(TextField),
    );

void main() {
  testWidgets('shows the full form for a standalone request', (tester) async {
    await _pumpRequest(tester);

    expect(find.text('Request an Item'), findsOneWidget);
    expect(find.textContaining('Your community is here to help.'),
        findsOneWidget);
    expect(find.text('Item name'), findsOneWidget);
    expect(find.text('Why do you need it?'), findsOneWidget);
    expect(find.text('Shown to donors when they review requests'),
        findsOneWidget);
    expect(find.text('Submit Request'), findsOneWidget);
  });

  testWidgets('submitting an empty form shows field errors', (tester) async {
    await _pumpRequest(tester);

    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter the item name'), findsOneWidget);
    expect(find.text('Please add a short description'), findsOneWidget);
    expect(find.text('Please select a category'), findsOneWidget);
    expect(find.text('Please tell donors why you need it'), findsOneWidget);
  });

  testWidgets('saves the item name and notes with the request',
      (tester) async {
    final requests = await _pumpRequest(tester);

    await tester.enterText(
        _field('e.g. Grade 10 Science Textbook'), 'School bag');
    await tester.enterText(
      _field('What exactly do you need? Size, edition, or any details'),
      'A sturdy bag for grade 6',
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('School Supplies').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      _field('A short reason helps donors choose fairly'),
      'My old bag is torn',
    );
    await tester.enterText(
        _field('Anything else donors should know'), 'Any colour is fine');

    await tester.runAsync(() async {
      await tester.tap(find.text('Submit Request'));
      await Future<void>.delayed(const Duration(seconds: 1));
    });
    await tester.pumpAndSettle();

    final created =
        requests.allRequests.where((r) => r.itemName == 'School bag');
    expect(created, hasLength(1));
    expect(created.single.notes, 'Any colour is fine');
    expect(created.single.category, 'School Supplies');
  });

  testWidgets('a request for a post only asks why', (tester) async {
    await _pumpRequest(tester, postId: 'p1');

    expect(find.text("You're requesting"), findsOneWidget);
    expect(find.text('Grade 10 Science Textbook'), findsOneWidget);
    expect(find.text('Item name'), findsNothing);
    expect(find.text('Select a category'), findsNothing);
    expect(find.text('Why do you need it?'), findsOneWidget);
  });

  for (final code in const ['en', 'si', 'ta']) {
    testWidgets('does not overflow in $code at 320 wide', (tester) async {
      await _pumpRequest(
        tester,
        size: const Size(320, 568),
        locale: Locale(code),
      );
      await tester.tap(find.byType(SLButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
