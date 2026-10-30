import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shareloop/controllers/auth_controller.dart';
import 'package:shareloop/controllers/badge_controller.dart';
import 'package:shareloop/controllers/item_controller.dart';
import 'package:shareloop/controllers/language_controller.dart';
import 'package:shareloop/controllers/profile_controller.dart';
import 'package:shareloop/controllers/request_controller.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/models/user_model.dart';
import 'package:shareloop/repositories/mock/mock_user_repository.dart';
import 'package:shareloop/services/location_service.dart';
import 'package:shareloop/services/mock_data_service.dart';
import 'package:shareloop/views/home/home_screen.dart';
import 'package:shareloop/views/profile/edit_profile_screen.dart';
import 'package:shareloop/widgets/item_grid_card.dart';

import 'support/fake_location_service.dart';

const _localizations = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Lets fake delays (mock repository saves) and animations finish.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  await tester.pumpAndSettle();
}

/// Signs in Nimal (Colombo, Nugegoda) and shows Home with [location] as
/// the device.
Future<AuthController> _pumpHome(
  WidgetTester tester,
  LocationService location,
) async {
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
        ChangeNotifierProvider(create: (_) => LanguageController()),
        Provider<LocationService>.value(value: location),
      ],
      child: const MaterialApp(
        localizationsDelegates: _localizations,
        supportedLocales: [Locale('en'), Locale('si'), Locale('ta')],
        home: HomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

/// Opens the Home city chip and taps "Use my location".
Future<void> _useMyLocationOnHome(WidgetTester tester) async {
  await tester.tap(find.text('Nugegoda'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Use my location'));
  await _settle(tester);
}

void main() {
  // The mock users are shared by every test in this file; put them back.
  late List<UserModel> seededUsers;
  setUp(() => seededUsers = List.of(MockDataService.instance.users));
  tearDown(() {
    MockDataService.instance.users
      ..clear()
      ..addAll(seededUsers);
  });

  group('Home "Use my location"', () {
    testWidgets('detects Gampaha / Negombo and updates profile and Home', (
      tester,
    ) async {
      final auth = await _pumpHome(tester, FakeLocationService.negombo());
      expect(find.text('Nugegoda'), findsOneWidget);

      await _useMyLocationOnHome(tester);

      expect(auth.currentUser!.district, 'Gampaha');
      expect(auth.currentUser!.city, 'Negombo');
      expect(find.text('Location set to Negombo, Gampaha.'), findsOneWidget);
      // The chip and the existing city filter follow at once.
      expect(find.text('Negombo'), findsOneWidget);
      expect(find.text('Leather School Backpack'), findsOneWidget);
      expect(find.byType(ItemGridCard), findsNWidgets(2));
      // Saved through the profile flow, so the Profile tab shows it too.
      await tester.tap(find.text('Profile'));
      await _settle(tester);
      expect(find.text('Negombo, Gampaha'), findsOneWidget);
    });

    testWidgets('explains first, then asks for foreground permission', (
      tester,
    ) async {
      final location = FakeLocationService.negombo(
        access: LocationAccess.askable,
      );
      final auth = await _pumpHome(tester, location);

      await _useMyLocationOnHome(tester);
      expect(find.text('Use your location?'), findsOneWidget);
      expect(location.requestCalls, 0);

      await tester.tap(find.text('Continue'));
      await _settle(tester);

      expect(location.requestCalls, 1);
      expect(auth.currentUser!.city, 'Negombo');
      expect(find.text('Negombo'), findsOneWidget);
    });

    testWidgets('"Not now" leaves everything as it was', (tester) async {
      final location = FakeLocationService.negombo(
        access: LocationAccess.askable,
      );
      final auth = await _pumpHome(tester, location);

      await _useMyLocationOnHome(tester);
      await tester.tap(find.text('Not now'));
      await _settle(tester);

      expect(location.requestCalls, 0);
      expect(auth.currentUser!.city, 'Nugegoda');
      expect(find.text('Nugegoda'), findsOneWidget);
    });

    testWidgets('only a district: its cities are offered to pick from', (
      tester,
    ) async {
      final auth = await _pumpHome(
        tester,
        FakeLocationService.negombo(accuracy: 2500),
      );

      await _useMyLocationOnHome(tester);

      expect(
        find.text("You're in Gampaha district. Please choose your city."),
        findsOneWidget,
      );
      expect(find.text('District: Gampaha'), findsOneWidget);
      expect(auth.currentUser!.city, 'Nugegoda'); // nothing assumed yet

      final negombo = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Negombo'),
      );
      await tester.scrollUntilVisible(
        negombo,
        150,
        scrollable: find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(negombo);
      await _settle(tester);

      expect(auth.currentUser!.district, 'Gampaha');
      expect(auth.currentUser!.city, 'Negombo');
      expect(find.text('Negombo'), findsOneWidget);
    });

    final failures = <String, LocationService>{
      "Location permission wasn't given. You can choose your city instead.":
          FakeLocationService.negombo(
            access: LocationAccess.askable,
            accessAfterRequest: LocationAccess.askable,
          ),
      'Location access is blocked for ShareLoop. Allow it in Settings, or '
          'choose your city.': FakeLocationService.negombo(
        access: LocationAccess.blocked,
      ),
      'Location services are turned off. Turn them on, or choose your city.':
          FakeLocationService.negombo(serviceEnabled: false),
      'Finding your location works in the ShareLoop app on Android and '
              'iPhone. Please choose your district and city.':
          FakeLocationService.negombo(supported: false),
      "Couldn't look up your area. Check your internet connection, or "
          'choose your city.': FakeLocationService.negombo(
        geocodeError: StateError('offline'),
      ),
    };
    for (final MapEntry(key: message, value: location) in failures.entries) {
      testWidgets('falls back to the manual choice: $message', (tester) async {
        final auth = await _pumpHome(tester, location);

        await _useMyLocationOnHome(tester);
        if (find.text('Continue').evaluate().isNotEmpty) {
          await tester.tap(find.text('Continue'));
          await _settle(tester);
        }

        expect(find.text(message), findsOneWidget);
        expect(auth.currentUser!.district, 'Colombo');
        expect(auth.currentUser!.city, 'Nugegoda');
        expect(find.text('Nugegoda'), findsOneWidget);
        // The manual picker still works.
        await tester.tap(find.text('Nugegoda'));
        await tester.pumpAndSettle();
        expect(find.text('Choose your city'), findsOneWidget);
      });
    }
  });

  testWidgets('Edit Profile fills District and City; Save keeps them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = AuthController();
    final profile = ProfileController();
    await tester.runAsync(() async {
      await auth.login('nimal@example.com', 'x');
      await profile.loadProfile(auth.currentUser!.id);
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: profile),
          Provider<LocationService>.value(value: FakeLocationService.negombo()),
        ],
        child: MaterialApp(
          localizationsDelegates: _localizations,
          supportedLocales: const [Locale('en')],
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Nugegoda'), findsOneWidget);

    await tester.ensureVisible(find.text('Use my location'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use my location'));
    await _settle(tester);

    expect(find.text('Gampaha'), findsOneWidget);
    expect(find.text('Negombo'), findsOneWidget);
    expect(
      find.text('Found Negombo, Gampaha. Tap Save Changes to keep it.'),
      findsOneWidget,
    );
    expect(auth.currentUser!.city, 'Nugegoda'); // not saved until Save

    await tester.tap(find.text('Save Changes'));
    await _settle(tester);

    expect(auth.currentUser!.district, 'Gampaha');
    expect(auth.currentUser!.city, 'Negombo');
    expect(find.byType(EditProfileScreen), findsNothing);
  });

  group('device-local persistence', () {
    test('a saved location is restored at sign-in after a restart', () async {
      final repository = MockUserRepository();
      final nimal = (await repository.login('nimal@example.com', 'x'))!;
      await repository.updateUser(
        nimal.copyWith(district: 'Gampaha', city: 'Negombo'),
      );

      // Restart: memory is back to the sample data, the device keeps its
      // preferences.
      final prefs = await SharedPreferences.getInstance();
      final kept = {
        for (final key in prefs.getKeys()) key: prefs.getString(key)!,
      };
      final users = MockDataService.instance.users;
      users[users.indexWhere((u) => u.id == nimal.id)] = nimal;
      SharedPreferences.setMockInitialValues(kept);

      final restored = (await MockUserRepository().login(
        'nimal@example.com',
        'x',
      ))!;
      expect(restored.district, 'Gampaha');
      expect(restored.city, 'Negombo');
      expect(
        (await MockUserRepository().getUserById(nimal.id))!.city,
        'Negombo',
      );
    });

    test('nothing saved: the profile is left as it is', () async {
      final user = (await MockUserRepository().login(
        'nimal@example.com',
        'x',
      ))!;
      expect(user.district, 'Colombo');
      expect(user.city, 'Nugegoda');
    });

    test('an unreadable saved value is ignored', () async {
      SharedPreferences.setMockInitialValues({
        'profile_location.u1': 'not json',
      });
      final user = (await MockUserRepository().login(
        'nimal@example.com',
        'x',
      ))!;
      expect(user.city, 'Nugegoda');
    });
  });
}
