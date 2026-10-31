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
import 'package:shareloop/models/item_post_model.dart';
import 'package:shareloop/services/mock_data_service.dart';
import 'package:shareloop/views/give_away/item_details_screen.dart';
import 'package:shareloop/views/home/home_screen.dart';
import 'package:shareloop/widgets/sl/sl_item_card.dart';

/// The mock store is shared by every test, so each test deletes a post
/// made just for it rather than seed data other tests rely on.
void _addOwnPost(String id, String title) {
  MockDataService.instance.itemPosts.add(
    ItemPostModel(
      id: id,
      donorId: 'u1',
      donorName: 'Nimal Perera',
      title: title,
      description: 'Works fine.',
      condition: 'Good',
      category: 'Electronics',
      district: 'Colombo',
      city: 'Nugegoda',
      createdAt: DateTime.now(),
    ),
  );
}

Future<void> _pumpHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
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
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
        home: const HomeScreen(),
        onGenerateRoute: (settings) => settings.name == AppRoutes.itemDetails
            ? MaterialPageRoute(
                builder: (_) =>
                    ItemDetailsScreen(postId: settings.arguments as String),
              )
            : null,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens [title]'s details from the feed and taps "Delete post".
Future<void> _deleteFromDetails(WidgetTester tester, String title) async {
  await tester.scrollUntilVisible(
    find.text(title),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.text(title));
  await tester.pumpAndSettle();
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Delete post'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete post'));
  await tester.pumpAndSettle();
}

Future<void> _confirmDelete(WidgetTester tester) async {
  expect(find.text('Delete this post?'), findsOneWidget);
  await tester.runAsync(() async {
    await tester.tap(find.text('Delete'));
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the feed has no delete buttons, even on your own posts', (
    tester,
  ) async {
    _addOwnPost('p-delete-none', 'Old desk lamp');
    await _pumpHome(tester);

    expect(find.byType(SLItemCard), findsWidgets);
    expect(find.byTooltip('Delete post'), findsNothing);
  });

  testWidgets('cancelling the delete keeps the post', (tester) async {
    _addOwnPost('p-delete-cancel', 'Folding chair');
    await _pumpHome(tester);

    await _deleteFromDetails(tester, 'Folding chair');
    expect(find.text('Delete this post?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(ItemDetailsScreen), findsOneWidget);
    expect(find.text('Folding chair'), findsWidgets);
  });

  testWidgets('deleting from item details goes back to the feed', (
    tester,
  ) async {
    _addOwnPost('p-delete-details', 'Spare kettle');
    await _pumpHome(tester);

    await _deleteFromDetails(tester, 'Spare kettle');
    await _confirmDelete(tester);

    expect(find.byType(ItemDetailsScreen), findsNothing);
    expect(find.text('Spare kettle'), findsNothing);
    expect(find.text('Post deleted.'), findsOneWidget);
  });
}
