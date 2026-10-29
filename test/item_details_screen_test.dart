import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shareloop/controllers/auth_controller.dart';
import 'package:shareloop/controllers/badge_controller.dart';
import 'package:shareloop/controllers/item_controller.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/views/give_away/item_details_screen.dart';
import 'package:shareloop/widgets/photo_viewer.dart';

/// Opens the details of mock post p3 (Nimal's white T-shirt), signed in as
/// [email] (Kamani by default, so not the owner).
Future<void> _openDetails(
  WidgetTester tester, {
  String email = 'kamani@example.com',
  Size size = const Size(390, 844),
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = AuthController();
  final items = ItemController();
  await tester.runAsync(() async {
    await auth.login(email, 'x');
    await items.loadPosts();
  });

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: items),
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
        home: const ItemDetailsScreen(postId: 'p3'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the post, its tags, the donor and the privacy note', (
    tester,
  ) async {
    await _openDetails(tester);

    expect(find.text('White Cotton T-Shirt'), findsOneWidget);
    expect(find.text('Used'), findsOneWidget);
    expect(find.text('Clothes'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Colombo, Nugegoda'), findsOneWidget);
    expect(find.textContaining('Posted '), findsOneWidget);
    expect(find.text('Nimal Perera'), findsOneWidget);
    expect(find.text('Silver donor'), findsOneWidget);
    expect(find.text('4.6'), findsOneWidget);
    expect(find.text('12 items given'), findsOneWidget);
    expect(find.textContaining('Contact details stay private'), findsOneWidget);
    expect(find.byTooltip('Share'), findsOneWidget);
    expect(find.text('Request this item'), findsOneWidget);
  });

  testWidgets('the donor sees their incoming requests instead', (
    tester,
  ) async {
    await _openDetails(tester, email: 'nimal@example.com');

    expect(find.text('View incoming requests'), findsOneWidget);
    expect(find.text('Request this item'), findsNothing);
  });

  testWidgets('tapping the photo opens a zoomable full-screen viewer', (
    tester,
  ) async {
    await _openDetails(tester);

    await tester.tap(find.bySemanticsLabel('View photo full screen'));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewer), findsOneWidget);

    double scale() => tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value
        .getMaxScaleOnAxis();
    expect(scale(), 1);

    // Double-tap zooms in, and again zooms back out.
    final photo = find.byType(InteractiveViewer);
    await tester.tap(photo);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(photo);
    await tester.pumpAndSettle();
    expect(scale(), greaterThan(1));

    await tester.tap(photo);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(photo);
    await tester.pumpAndSettle();
    expect(scale(), 1);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewer), findsNothing);
    expect(find.text('White Cotton T-Shirt'), findsOneWidget);
  });

  for (final locale in const [Locale('en'), Locale('si'), Locale('ta')]) {
    testWidgets('does not overflow in ${locale.languageCode} at 320 wide', (
      tester,
    ) async {
      await _openDetails(tester, size: const Size(320, 568), locale: locale);
      expect(tester.takeException(), isNull);
    });
  }
}
