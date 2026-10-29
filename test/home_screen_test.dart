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
import 'package:shareloop/views/home/home_screen.dart';
import 'package:shareloop/widgets/item_grid_card.dart';
import 'package:shareloop/widgets/app_icon.dart';

Future<void> _pumpHome(
  WidgetTester tester, {
  Size size = const Size(390, 844),
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
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('si'), Locale('ta')],
        home: HomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows greeting, shortcuts and the item grid', (tester) async {
    await _pumpHome(tester);

    expect(find.text('Hello, Nimal. What are you sharing today?'),
        findsOneWidget);
    expect(find.text('Give an Item'), findsOneWidget);
    expect(find.text('Request an Item'), findsOneWidget);
    expect(find.text('Available near you'), findsOneWidget);
    expect(find.text('All districts'), findsOneWidget);
    expect(find.byType(ItemGridCard), findsWidgets);
    // The grid builds lazily, so scroll until a Silver donor's card exists.
    await tester.scrollUntilVisible(
      find.textContaining('Silver donor'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Silver donor'), findsWidgets);
  });

  testWidgets('sample posts show their bundled photos', (tester) async {
    await _pumpHome(tester);

    Finder assetImage(String name) => find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == name,
    );

    // The newest posts are at the top; older ones are built as you scroll.
    expect(assetImage('assets/images/item_grey_cap.jpg'), findsOneWidget);
    expect(
      assetImage('assets/images/item_slip_on_sneakers.jpg'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      assetImage('assets/images/item_pressure_cooker.jpg'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      assetImage('assets/images/item_pressure_cooker.jpg'),
      findsOneWidget,
    );
  });

  testWidgets('category chip filters the grid', (tester) async {
    await _pumpHome(tester);

    await tester.ensureVisible(find.text('Shoes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shoes'));
    await tester.pumpAndSettle();

    expect(find.byType(ItemGridCard), findsNWidgets(2));
    expect(find.text('Leather Wingtip Brogues (Size 9)'), findsOneWidget);
    expect(find.text('Slip-On Knit Sneakers (Size 8)'), findsOneWidget);
  });

  testWidgets('district picker filters the grid', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.text('All districts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galle'));
    await tester.pumpAndSettle();

    expect(find.text('Electric Pressure Cooker'), findsOneWidget);
    expect(find.text('Smartphone'), findsOneWidget);
    expect(find.byType(ItemGridCard), findsNWidgets(2));
  });

  testWidgets('switches to community requests', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.text('Requests').first);
    await tester.pumpAndSettle();

    expect(find.text('Open requests'), findsOneWidget);
    expect(find.byType(ItemGridCard), findsNothing);
    expect(find.text('Grade 5 A/L notes for Maths'), findsOneWidget);
  });

  testWidgets('Give tab shows the form above the nav bar', (tester) async {
    await _pumpHome(tester);

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is AppIcon && w.glyph == AppGlyph.give,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Publish Item'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );

    // The form's back button returns to the Home tab.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Available near you'), findsOneWidget);
  });

  testWidgets('Give an Item card opens the Give tab', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.text('Give an Item'));
    await tester.pumpAndSettle();

    expect(find.text('Publish Item'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  for (final size in const [Size(320, 568), Size(360, 800)]) {
    testWidgets('does not overflow at $size', (tester) async {
      await _pumpHome(tester, size: size);
      expect(tester.takeException(), isNull);
    });
  }
}
