import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shareloop/controllers/auth_controller.dart';
import 'package:shareloop/controllers/badge_controller.dart';
import 'package:shareloop/controllers/item_controller.dart';
import 'package:shareloop/controllers/language_controller.dart';
import 'package:shareloop/controllers/profile_controller.dart';
import 'package:shareloop/controllers/request_controller.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/views/home/home_screen.dart';
import 'package:shareloop/widgets/sl/sl_item_card.dart';
import 'package:shareloop/widgets/app_icon.dart';
import 'package:shareloop/widgets/sl/sl_chip.dart';
import 'package:shareloop/widgets/user_avatar.dart';

Future<AuthController> _pumpHome(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  String email = 'nimal@example.com',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = AuthController();
  await tester.runAsync(() => auth.login(email, 'x'));

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => ItemController()),
        ChangeNotifierProvider(create: (_) => RequestController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => BadgeController()),
        ChangeNotifierProvider(create: (_) => LanguageController()),
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
  return auth;
}

/// Home starts filtered to the user's city; this widens it to every area.
Future<void> _showAllAreas(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.location_on_outlined).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('All areas'));
  await tester.pumpAndSettle();
}

/// Scrolls the city picker sheet's list to [label] and taps it, letting a
/// resulting profile save finish.
Future<void> _pickInSheet(WidgetTester tester, String label) async {
  final item = find.descendant(
    of: find.byType(BottomSheet),
    matching: find.text(label),
  );
  await tester.scrollUntilVisible(
    item,
    150,
    scrollable: find
        .descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(item);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the compact header, category chips and the item grid', (
    tester,
  ) async {
    await _pumpHome(tester);

    // A compact header: the wordmark and the photo, no greeting.
    expect(find.bySemanticsLabel('ShareLoop'), findsOneWidget);
    expect(find.textContaining('Hello'), findsNothing);
    // The Give/Request shortcuts and the Give Away/Requests switch are gone;
    // both live in the bottom navigation.
    expect(find.text('Give an Item'), findsNothing);
    expect(find.text('Request an Item'), findsNothing);
    // "All" plus one chip per category, then the city chip.
    expect(find.widgetWithText(SLChip, 'All'), findsOneWidget);
    expect(find.widgetWithText(SLChip, 'Household Items'), findsOneWidget);
    expect(find.byType(SLChip), findsNWidgets(9));
    expect(find.text('Available near you'), findsOneWidget);
    // Cards only open the post: no delete buttons in the feed.
    expect(find.byTooltip('Delete post'), findsNothing);
    // Nimal lives in Nugegoda, so Home starts with items there.
    expect(find.text('All districts'), findsNothing);
    expect(find.text('Nugegoda'), findsOneWidget);
    expect(find.byType(SLItemCard), findsWidgets);
    // Cards show the donor's first name; their badge is the dot on the
    // photo, and screen readers hear it.
    expect(find.textContaining('Nimal · '), findsWidgets);
    final semantics = tester.ensureSemantics();
    expect(
      // The card merges its texts into one label for screen readers.
      find.bySemanticsLabel(RegExp('Nimal, Silver donor, ')),
      findsWidgets,
    );
    semantics.dispose();
  });

  testWidgets('header follows profile edits: new photo and name', (
    tester,
  ) async {
    final auth = await _pumpHome(tester);
    expect(find.byType(UserAvatar), findsNothing);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);

    auth.updateCurrentUser(
      auth.currentUser!.copyWith(
        name: 'Kavidu Himansa',
        avatarUrl: 'assets/images/item_grey_cap.jpg',
      ),
    );
    await tester.pumpAndSettle();

    final newPhoto = find.byWidgetPredicate(
      (w) => w is UserAvatar && w.url == 'assets/images/item_grey_cap.jpg',
    );
    // The header photo (the bottom bar's Profile tab shares the tooltip).
    final headerPhoto = find.descendant(
      of: find.byWidgetPredicate((w) => w is Tooltip && w.message == 'Profile'),
      matching: newPhoto,
    );
    expect(headerPhoto, findsOneWidget);
    // Nimal's own posts in the grid show the new photo too.
    expect(
      find.descendant(of: find.byType(SLItemCard), matching: newPhoto),
      findsWidgets,
    );
    await tester.tap(headerPhoto);
    await tester.pumpAndSettle();
    expect(find.text('My Profile'), findsOneWidget);
  });

  testWidgets('sample posts show their bundled photos', (tester) async {
    await _pumpHome(tester);
    await _showAllAreas(tester);

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

  testWidgets('a category chip filters the grid', (tester) async {
    await _pumpHome(tester);
    await _showAllAreas(tester);
    final shoes = find.widgetWithText(SLChip, 'Shoes');

    await tester.ensureVisible(shoes);
    await tester.pumpAndSettle();
    await tester.tap(shoes);
    await tester.pumpAndSettle();

    expect(find.byType(SLItemCard), findsNWidgets(2));
    expect(find.text('Leather Wingtip Brogues (Size 9)'), findsOneWidget);
    expect(find.text('Slip-On Knit Sneakers (Size 8)'), findsOneWidget);
    expect(tester.widget<SLChip>(shoes).selected, isTrue);

    final all = find.widgetWithText(SLChip, 'All');
    await tester.ensureVisible(all);
    await tester.pumpAndSettle();
    await tester.tap(all);
    await tester.pumpAndSettle();
    expect(tester.widget<SLChip>(shoes).selected, isFalse);
  });

  group('location chip', () {
    testWidgets('shows the profile city and only items there', (tester) async {
      // Kamani's profile: Gampaha district, Negombo.
      await _pumpHome(tester, email: 'kamani@example.com');

      expect(find.text('Negombo'), findsOneWidget);
      expect(find.text('Gampaha'), findsNothing);
      expect(find.text('All districts'), findsNothing);
      expect(find.text('Leather School Backpack'), findsOneWidget);
      expect(find.text('Slip-On Knit Sneakers (Size 8)'), findsOneWidget);
      expect(find.byType(SLItemCard), findsNWidgets(2));
    });

    testWidgets('follows a profile change at once', (tester) async {
      final auth = await _pumpHome(tester);
      expect(find.text('Nugegoda'), findsOneWidget);

      // What Edit Profile does after saving.
      auth.updateCurrentUser(
        auth.currentUser!.copyWith(district: 'Galle', city: 'Hikkaduwa'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hikkaduwa'), findsOneWidget);
      expect(find.text('Electric Pressure Cooker'), findsOneWidget);
      expect(find.text('Smartphone'), findsOneWidget);
      expect(find.byType(SLItemCard), findsNWidgets(2));
    });

    testWidgets('without a city says "Select city", not the district', (
      tester,
    ) async {
      final auth = await _pumpHome(tester);
      auth.updateCurrentUser(auth.currentUser!.copyWith(city: ''));
      await tester.pumpAndSettle();

      expect(find.text('Select city'), findsOneWidget);
      expect(find.text('Colombo'), findsNothing);
      // No city, no city filter: every area's items show.
      expect(find.text('Washed Grey Baseball Cap'), findsOneWidget);

      // Picking one from the chip saves it to the profile.
      await tester.tap(find.text('Select city'));
      await tester.pumpAndSettle();
      expect(find.text('Choose your city'), findsOneWidget);
      expect(find.text('District: Colombo'), findsOneWidget);
      expect(find.text('All areas'), findsNothing);
      expect(find.text('Negombo'), findsNothing); // Gampaha, not Colombo
      await _pickInSheet(tester, 'Nugegoda');

      expect(auth.currentUser!.city, 'Nugegoda');
      expect(auth.currentUser!.district, 'Colombo');
      expect(find.text('Nugegoda'), findsOneWidget);
      expect(find.text('Washed Grey Baseball Cap'), findsNothing);
    });

    testWidgets('a city in another district updates both on the profile', (
      tester,
    ) async {
      final auth = await _pumpHome(tester);

      await tester.tap(find.text('Nugegoda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a district'), findsOneWidget);
      await _pickInSheet(tester, 'Gampaha');
      expect(find.text('District: Gampaha'), findsOneWidget);
      expect(find.text('Ja-Ela'), findsOneWidget);
      await _pickInSheet(tester, 'Negombo');

      expect(auth.currentUser!.district, 'Gampaha');
      expect(auth.currentUser!.city, 'Negombo');
      expect(find.text('Negombo'), findsOneWidget);
      expect(find.byType(SLItemCard), findsNWidgets(2));
    });

    testWidgets('"All areas" shows every item until the city changes', (
      tester,
    ) async {
      await _pumpHome(tester);
      expect(find.text('Washed Grey Baseball Cap'), findsNothing);

      await _showAllAreas(tester);

      expect(find.text('All areas'), findsOneWidget);
      expect(find.text('Washed Grey Baseball Cap'), findsOneWidget);
    });
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

  for (final size in const [Size(320, 568), Size(360, 800)]) {
    testWidgets('does not overflow at $size', (tester) async {
      await _pumpHome(tester, size: size);
      expect(tester.takeException(), isNull);
    });
  }
}
