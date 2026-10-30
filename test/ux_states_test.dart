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
import 'package:shareloop/core/errors/app_exception.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/models/item_post_model.dart';
import 'package:shareloop/models/user_model.dart';
import 'package:shareloop/repositories/mock/mock_item_post_repository.dart';
import 'package:shareloop/repositories/mock/mock_user_repository.dart';
import 'package:shareloop/views/give_away/create_give_away_screen.dart';
import 'package:shareloop/views/give_away/item_details_screen.dart';
import 'package:shareloop/views/home/home_screen.dart';
import 'package:shareloop/views/profile/edit_profile_screen.dart';
import 'package:shareloop/views/profile/profile_screen.dart';
import 'package:shareloop/widgets/app_icon.dart';
import 'package:shareloop/widgets/sl/sl_item_card.dart';

const _offline = 'No connection. Check your internet and try again.';

/// Fails to load while [failing], like a dropped connection.
class _FlakyPosts extends MockItemPostRepository {
  bool failing = true;

  @override
  Future<List<ItemPostModel>> getAllPosts({
    int limit = 50,
    int offset = 0,
  }) async {
    if (failing) throw const AppException(_offline);
    return super.getAllPosts(limit: limit, offset: offset);
  }
}

class _FlakyUsers extends MockUserRepository {
  bool failing = true;

  @override
  Future<UserModel?> getUserById(String id) async {
    if (failing) throw const AppException(_offline);
    return super.getUserById(id);
  }
}

/// Signs Nimal in and shows [home] with every controller the app provides.
Future<AuthController> _pump(
  WidgetTester tester,
  Widget home, {
  ItemController? items,
  ProfileController? profile,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = AuthController();
  await tester.runAsync(() => auth.login('nimal@example.com', 'x'));
  auth.takeJustSignedIn(); // no notification prompt in these tests

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: items ?? ItemController()),
        ChangeNotifierProvider(create: (_) => RequestController()),
        ChangeNotifierProvider.value(value: profile ?? ProfileController()),
        ChangeNotifierProvider(create: (_) => BadgeController()),
        ChangeNotifierProvider(create: (_) => LanguageController()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
        home: home,
      ),
    ),
  );
  await _settle(tester);
  return auth;
}

/// Lets the mock repositories' real delays finish.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 500)),
  );
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, AppGlyph glyph) async {
  await tester.tap(
    find.byWidgetPredicate((w) => w is AppIcon && w.glyph == glyph),
  );
  await tester.pumpAndSettle();
}

Finder get _searchField => find.byType(TextField).first;

/// Scrolls [label]'s button into view and taps it, letting the async work
/// it starts (e.g. a retry) really finish.
Future<void> _tapButton(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(find.text(label));
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pumpAndSettle();
}

void main() {
  group('Home feed', () {
    testWidgets('a failed load says so and retries, instead of "no items"', (
      tester,
    ) async {
      final posts = _FlakyPosts();
      await _pump(
        tester,
        const HomeScreen(),
        items: ItemController(repository: posts),
      );

      expect(find.text(_offline), findsOneWidget);
      expect(find.text('No items available right now.'), findsNothing);
      expect(find.byType(SLItemCard), findsNothing);

      posts.failing = false;
      await _tapButton(tester, 'Try again');
      await _settle(tester);

      expect(find.text(_offline), findsNothing);
      expect(find.byType(SLItemCard), findsWidgets);
    });

    testWidgets('no matches offers Clear filters, which resets the search', (
      tester,
    ) async {
      await _pump(tester, const HomeScreen());

      await tester.enterText(_searchField, 'zzzz-nothing');
      await tester.pumpAndSettle();
      expect(find.text('Nothing matches your search or filters.'),
          findsOneWidget);

      await _tapButton(tester, 'Clear filters');
      await tester.pumpAndSettle();

      expect(find.byType(SLItemCard), findsWidgets);
      expect(tester.widget<TextField>(_searchField).controller!.text, isEmpty);
    });

    testWidgets('the search box has a clear button while it has text', (
      tester,
    ) async {
      await _pump(tester, const HomeScreen());
      expect(find.byTooltip('Clear search'), findsNothing);

      await tester.enterText(_searchField, 'shoes');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(_searchField).controller!.text, isEmpty);
      expect(find.byTooltip('Clear search'), findsNothing);
    });
  });

  group('Give tab keeps typed input safe', () {
    testWidgets('leaving with input asks first; Cancel keeps it', (
      tester,
    ) async {
      await _pump(tester, const HomeScreen());
      await _openTab(tester, AppGlyph.give);
      await tester.enterText(find.byType(TextFormField).first, 'Desk lamp');

      await _openTab(tester, AppGlyph.home);
      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateGiveAwayScreen), findsOneWidget);
      expect(find.text('Desk lamp'), findsOneWidget);

      await _openTab(tester, AppGlyph.home);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateGiveAwayScreen), findsNothing);
      expect(find.text('Available near you'), findsOneWidget);
    });

    testWidgets('an untouched form leaves without asking', (tester) async {
      await _pump(tester, const HomeScreen());
      await _openTab(tester, AppGlyph.give);

      await _openTab(tester, AppGlyph.requests);

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.byType(CreateGiveAwayScreen), findsNothing);
    });
  });

  group('Edit Profile back navigation', () {
    Future<void> openEdit(WidgetTester tester) async {
      final profile = ProfileController();
      final auth = await _pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
        profile: profile,
      );
      await tester.runAsync(() => profile.loadProfile(auth.currentUser!.id));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('unchanged: back leaves at once', (tester) async {
      await openEdit(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileScreen), findsNothing);
    });

    testWidgets('edited: back asks before discarding', (tester) async {
      await openEdit(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nimal Perera'),
        'Nimal P.',
      );
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsNothing);
    });
  });

  testWidgets('Profile: a failed load offers a retry, not an endless '
      'spinner', (tester) async {
    final users = _FlakyUsers();
    final profile = ProfileController(userRepository: users);
    await _pump(
      tester,
      const Scaffold(body: ProfileScreen()),
      profile: profile,
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(_offline), findsOneWidget);

    users.failing = false;
    await _tapButton(tester, 'Try again');
    await _settle(tester);

    expect(find.text('Nimal Perera'), findsOneWidget);
  });

  testWidgets('item details opens even when the Home filters hide it', (
    tester,
  ) async {
    final items = ItemController();
    await tester.runAsync(items.loadPosts);
    // p1 is in Educational Books; a Shoes filter hides it from `posts`.
    items.setCategoryFilter('Shoes');
    expect(items.posts.where((p) => p.id == 'p1'), isEmpty);

    await _pump(
      tester,
      const ItemDetailsScreen(postId: 'p1'),
      items: items,
    );

    expect(find.text('Grade 10 Science Textbook'), findsWidgets);
  });
}
