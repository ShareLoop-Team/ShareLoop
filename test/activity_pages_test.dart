import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shareloop/controllers/auth_controller.dart';
import 'package:shareloop/controllers/badge_controller.dart';
import 'package:shareloop/controllers/profile_controller.dart';
import 'package:shareloop/controllers/item_controller.dart';
import 'package:shareloop/controllers/request_controller.dart';
import 'package:shareloop/models/exchange_model.dart';
import 'package:shareloop/models/email_code.dart';
import 'package:shareloop/repositories/mock/mock_user_repository.dart';
import 'package:shareloop/services/mock_data_service.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/core/theme/app_theme.dart';
import 'package:shareloop/views/profile/my_donations_screen.dart';
import 'package:shareloop/views/profile/my_requests_screen.dart';
import 'package:shareloop/views/profile/my_reviews_screen.dart';
import 'package:shareloop/views/profile/my_exchanges_screen.dart';

/// Pumps [page] for a signed-in user: Nimal (has posts, a request and a
/// review), or a brand-new account with nothing yet when [newUser] is set.
Future<void> _pumpPage(
  WidgetTester tester,
  Widget page, {
  bool newUser = false,
  Size size = const Size(390, 844),
  Locale locale = const Locale('en'),
  bool darkTheme = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = AuthController();
  final profile = ProfileController();
  await tester.runAsync(() async {
    if (newUser) {
      await auth.register(
        PendingRegistration(
          name: 'Ama Test',
          email: 'ama${DateTime.now().microsecondsSinceEpoch}@example.com',
          password: 'secret1',
          phone: '0771234567',
          district: 'Colombo',
          city: 'Dehiwala',
        ),
        MockUserRepository.mockCode,
      );
    } else {
      await auth.login('nimal@example.com', 'x');
    }
    await profile.loadProfile(auth.currentUser!.id);
  });

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: profile),
        ChangeNotifierProvider(create: (_) => BadgeController()),
        ChangeNotifierProvider(create: (_) => ItemController()),
        ChangeNotifierProvider(create: (_) => RequestController()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: darkTheme ? ThemeMode.dark : ThemeMode.light,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('empty states', () {
    testWidgets('My Requests invites a first request', (tester) async {
      await _pumpPage(tester, const MyRequestsScreen(), newUser: true);

      expect(find.text('My Requests'), findsOneWidget);
      expect(find.text('Items you have asked for'), findsOneWidget);
      expect(find.text('No requests yet'), findsOneWidget);
      expect(find.textContaining('honest reason'), findsOneWidget);
      expect(find.text('Request an item'), findsOneWidget);
    });

    testWidgets('My Donations shows the first badge to earn', (tester) async {
      await _pumpPage(tester, const MyDonationsScreen(), newUser: true);

      expect(find.text('No donations yet'), findsOneWidget);
      expect(find.text('Bronze badge'), findsOneWidget);
      expect(find.text('0 of 5 items'), findsOneWidget);
      expect(
        find.text('Give 5 items to become a New Contributor'),
        findsOneWidget,
      );
      expect(find.text('Give your first item'), findsOneWidget);
    });

    testWidgets('Reviews explains how to get one', (tester) async {
      await _pumpPage(tester, const MyReviewsScreen(), newUser: true);

      expect(find.text('No reviews yet'), findsOneWidget);
      expect(find.text('Get your first review'), findsOneWidget);
      expect(find.text('Browse items'), findsOneWidget);
    });

    testWidgets('My Exchanges explains the two-person confirmation', (
      tester,
    ) async {
      await _pumpPage(tester, const MyExchangesScreen(), newUser: true);
      expect(find.text('No exchanges yet'), findsOneWidget);
      expect(find.textContaining('both people confirm'), findsOneWidget);
    });
  });

  group('with activity', () {
    testWidgets('My Requests lists the requests', (tester) async {
      await _pumpPage(tester, const MyRequestsScreen());

      expect(find.text('No requests yet'), findsNothing);
      expect(find.text('Grade 5 A/L notes for Maths'), findsOneWidget);
      expect(find.text('School shoes, size 4'), findsNothing);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('My Donations lists the posts after the badge card', (
      tester,
    ) async {
      await _pumpPage(tester, const MyDonationsScreen());

      expect(find.text('Gold badge'), findsOneWidget);
      expect(find.text('White Cotton T-Shirt'), findsOneWidget);
      expect(find.text('Leather School Backpack'), findsNothing);
      expect(find.text('Give an item'), findsOneWidget);
    });

    testWidgets('Reviews shows the average and each review', (tester) async {
      await _pumpPage(tester, const MyReviewsScreen());

      expect(find.text('No reviews yet'), findsNothing);
      expect(find.text('1 review'), findsOneWidget);
      expect(find.text('5.0'), findsOneWidget);
      expect(find.text('Kamani Silva'), findsOneWidget);
      expect(find.text('Grade 10 Science Textbook'), findsOneWidget);
    });

    testWidgets('My Exchanges lists real handovers and both confirmations', (
      tester,
    ) async {
      final data = MockDataService.instance;
      final exchange = ExchangeModel(
        id: 'x-activity-page-test',
        itemPostId: 'p1',
        requestId: 'r1',
        donorId: 'u1',
        requesterId: 'u2',
        status: ExchangeStatus.completed,
        donorConfirmedAt: DateTime.now(),
        requesterConfirmedAt: DateTime.now(),
      );
      data.exchanges.add(exchange);
      addTearDown(() => data.exchanges.removeWhere((e) => e.id == exchange.id));
      await _pumpPage(tester, const MyExchangesScreen());

      expect(find.text('Grade 10 Science Textbook'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Both people confirmed this handover.'), findsOneWidget);
    });
  });

  for (final locale in const [Locale('en'), Locale('si'), Locale('ta')]) {
    for (final (name, page) in const [
      ('requests', MyRequestsScreen()),
      ('donations', MyDonationsScreen()),
      ('reviews', MyReviewsScreen()),
      ('exchanges', MyExchangesScreen()),
    ]) {
      testWidgets(
        'empty $name page does not overflow in ${locale.languageCode} '
        'at 320 wide',
        (tester) async {
          await _pumpPage(
            tester,
            page,
            newUser: true,
            size: const Size(320, 568),
            locale: locale,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final (name, page) in const [
    ('requests', MyRequestsScreen()),
    ('donations', MyDonationsScreen()),
    ('reviews', MyReviewsScreen()),
    ('exchanges', MyExchangesScreen()),
  ]) {
    testWidgets('empty $name page supports dark theme', (tester) async {
      await _pumpPage(tester, page, newUser: true, darkTheme: true);
      expect(
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.dark,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
