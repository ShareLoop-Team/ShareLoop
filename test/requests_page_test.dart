import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shareloop/controllers/auth_controller.dart';
import 'package:shareloop/controllers/badge_controller.dart';
import 'package:shareloop/controllers/item_controller.dart';
import 'package:shareloop/controllers/profile_controller.dart';
import 'package:shareloop/controllers/request_controller.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/core/routes/app_routes.dart';
import 'package:shareloop/models/item_request_model.dart';
import 'package:shareloop/services/mock_data_service.dart';
import 'package:shareloop/views/give_away/create_give_away_screen.dart';
import 'package:shareloop/views/home/home_screen.dart';
import 'package:shareloop/widgets/category_chip.dart';
import 'package:shareloop/widgets/app_icon.dart';

/// Pumps the home shell and switches to the Requests tab.
Future<void> _pumpRequestsPage(
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
        ChangeNotifierProvider(create: (_) => RequestController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => BadgeController()),
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
        home: const HomeScreen(),
        onGenerateRoute: (settings) => settings.name ==
                AppRoutes.createGiveAway
            ? MaterialPageRoute(
                builder: (_) => CreateGiveAwayScreen(
                  forRequest: settings.arguments as ItemRequestModel?,
                ),
              )
            : null,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byWidgetPredicate(
      (w) => w is AppIcon && w.glyph == AppGlyph.requests,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists community requests with status and help button',
      (tester) async {
    await _pumpRequestsPage(tester);

    expect(find.text('People near you who need an item'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('All requests'), findsOneWidget);
    expect(find.text('Grade 5 A/L notes for Maths'), findsOneWidget);
    expect(find.text('School shoes, size 4'), findsOneWidget);
    expect(find.text('Open'), findsWidgets);
    // Nimal's own request has no "I can help"; others do.
    expect(find.text('I can help'), findsWidgets);
  });

  testWidgets('category chip narrows the list', (tester) async {
    await _pumpRequestsPage(tester);

    final shoesChip = find.widgetWithText(CategoryChip, 'Shoes');
    await tester.ensureVisible(shoesChip);
    await tester.pumpAndSettle();
    await tester.tap(shoesChip);
    await tester.pumpAndSettle();

    expect(find.text('School shoes, size 4'), findsOneWidget);
    expect(find.text('Grade 5 A/L notes for Maths'), findsNothing);
  });

  testWidgets('My requests shows only the user\'s requests', (tester) async {
    await _pumpRequestsPage(tester);

    await tester.tap(find.text('My requests'));
    await tester.pumpAndSettle();

    expect(find.text('Grade 5 A/L notes for Maths'), findsOneWidget);
    expect(find.text('School shoes, size 4'), findsNothing);
    expect(find.text('I can help'), findsNothing);
  });

  testWidgets('deleting your own request asks first, then removes it',
      (tester) async {
    // The mock store is shared by every test, so delete a request made
    // just for this test rather than seed data other tests rely on.
    MockDataService.instance.itemRequests.add(
      ItemRequestModel(
        id: 'r-delete-test',
        requesterId: 'u1',
        requesterName: 'Nimal Perera',
        itemName: 'Phone charger',
        description: 'Any USB-C charger',
        reason: 'Mine stopped working.',
        category: 'Electronics',
        district: 'Colombo',
        city: 'Nugegoda',
        createdAt: DateTime.now(),
      ),
    );
    await _pumpRequestsPage(tester);
    await tester.tap(find.text('My requests'));
    await tester.pumpAndSettle();

    // Newest first, so the test request's delete button comes first.
    final deleteButton = find.byTooltip('Delete request').first;
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(find.text('Delete this request?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Phone charger'), findsOneWidget);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Delete'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(find.text('Phone charger'), findsNothing);
    expect(find.text('Grade 5 A/L notes for Maths'), findsOneWidget);
    expect(find.text('Request deleted.'), findsOneWidget);
  });

  testWidgets('other people\'s requests have no delete button',
      (tester) async {
    await _pumpRequestsPage(tester);

    expect(find.text('School shoes, size 4'), findsOneWidget);
    // Only Nimal's own request in the list can be deleted.
    expect(find.byTooltip('Delete request'), findsOneWidget);
  });

  testWidgets('I can help opens the Give form pre-filled', (tester) async {
    await _pumpRequestsPage(tester);

    await tester.tap(find.text('I can help').first);
    await tester.pumpAndSettle();

    expect(find.text('Give an Item'), findsOneWidget);
    expect(find.text('School shoes, size 4'), findsOneWidget);
    expect(find.text('Shoes'), findsOneWidget);
  });

  for (final code in const ['en', 'si', 'ta']) {
    testWidgets('does not overflow in $code at 320 wide', (tester) async {
      await _pumpRequestsPage(
        tester,
        size: const Size(320, 568),
        locale: Locale(code),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
