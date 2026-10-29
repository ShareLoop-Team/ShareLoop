import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shareloop/controllers/auth_controller.dart';
import 'package:shareloop/controllers/profile_controller.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/models/photo_upload.dart';
import 'package:shareloop/views/profile/edit_profile_screen.dart';
import 'package:shareloop/widgets/city_dropdown_field.dart';
import 'package:shareloop/widgets/user_avatar.dart';

/// Signs in mock user u4 (Priya) and opens Edit Profile on top of a
/// stand-in page, so saving can pop back to it.
Future<({AuthController auth, ProfileController profile})> _openEditProfile(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = AuthController();
  final profile = ProfileController();
  await tester.runAsync(() async {
    await auth.login('priya@example.com', 'x');
    await profile.loadProfile(auth.currentUser!.id);
  });

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: profile),
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
  return (auth: auth, profile: profile);
}

Finder _fieldWithText(String text) =>
    find.widgetWithText(TextFormField, text);

void main() {
  testWidgets('shows the profile filled in, with the email locked', (
    tester,
  ) async {
    await _openEditProfile(tester);

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Change photo'), findsOneWidget);
    expect(find.byType(UserAvatar), findsOneWidget);
    expect(_fieldWithText('Priya Rajan'), findsOneWidget);
    expect(find.text('Your email cannot be changed'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsWidgets);
    final email = tester.widget<TextField>(
      find.descendant(
        of: _fieldWithText('priya@example.com'),
        matching: find.byType(TextField),
      ),
    );
    expect(email.enabled, isFalse);
    expect(find.text('Kandy'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('rejects an invalid phone number', (tester) async {
    await _openEditProfile(tester);

    final phone = find.byType(TextFormField).at(2);
    await tester.enterText(phone, 'abc');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid phone number'), findsOneWidget);
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });

  testWidgets('saving updates the profile and goes back', (tester) async {
    final (:auth, :profile) = await _openEditProfile(tester);

    await tester.enterText(_fieldWithText('Priya Rajan'), 'Priya R.');
    await tester.runAsync(() async {
      await tester.tap(find.text('Save Changes'));
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pumpAndSettle();

    expect(profile.user?.name, 'Priya R.');
    // The signed-in user changes too, so e.g. the home greeting updates.
    expect(auth.currentUser?.name, 'Priya R.');
    expect(find.byType(EditProfileScreen), findsNothing);
    expect(find.text('Profile updated.'), findsOneWidget);
  });

  testWidgets('city list follows the district; Negombo saves under Gampaha', (
    tester,
  ) async {
    final (:auth, :profile) = await _openEditProfile(tester);
    expect(find.text('Kandy'), findsOneWidget);
    expect(find.text('Peradeniya'), findsOneWidget);

    // Kandy's towns only.
    await tester.tap(find.text('Peradeniya'));
    await tester.pumpAndSettle();
    expect(find.text('Gampola'), findsWidgets);
    expect(find.text('Negombo'), findsNothing);
    await tester.tap(find.text('Peradeniya').last);
    await tester.pumpAndSettle();

    // A new district drops Peradeniya and offers Gampaha's towns.
    await tester.tap(find.text('Kandy'));
    await tester.pumpAndSettle();
    // The menu opens at Kandy; Gampaha is further up.
    await tester.drag(find.text('Kandy').last, const Offset(0, 300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gampaha').last);
    await tester.pumpAndSettle();
    expect(find.text('Peradeniya'), findsNothing);
    expect(find.text('Select your city or town'), findsOneWidget);

    // Saving without a city is refused.
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(find.text('City / town is required'), findsOneWidget);

    await tester.tap(find.byType(CityDropdownField));
    await tester.pumpAndSettle();
    expect(find.text('Ja-Ela'), findsWidgets);
    await tester.drag(find.text('Ja-Ela').last, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Negombo').last);
    await tester.pumpAndSettle();
    expect(find.text('Negombo'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Save Changes'));
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pumpAndSettle();

    expect(profile.user?.district, 'Gampaha');
    expect(profile.user?.city, 'Negombo');
    expect(auth.currentUser?.city, 'Negombo');
    expect(find.byType(EditProfileScreen), findsNothing);
  });

  testWidgets('a city is disabled until a district is chosen', (
    tester,
  ) async {
    final (:auth, :profile) = await _openEditProfile(tester);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    // A profile from before districts were required: no district or city.
    profile.user = profile.user!.copyWith(district: '', city: 'Somewhere');
    auth.updateCurrentUser(profile.user!);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Somewhere'), findsNothing);
    expect(find.text('Select a district first'), findsOneWidget);
    final city = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>).last,
    );
    expect(city.onChanged, isNull);
  });

  testWidgets('a new photo is saved as the profile photo', (tester) async {
    final profile = ProfileController();
    await tester.runAsync(() async {
      await profile.loadProfile('u3');
      final user = profile.user!;
      final saved = await profile.updateProfile(
        name: user.name,
        phone: user.phone,
        district: user.district,
        city: user.city,
        photo: PhotoUpload(
          bytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/png',
          name: 'me.png',
        ),
      );
      expect(saved, isTrue);
    });

    expect(profile.user?.avatarUrl, startsWith('data:image/png;base64,'));
  });

  for (final locale in const [Locale('en'), Locale('si'), Locale('ta')]) {
    testWidgets('does not overflow in ${locale.languageCode} at 320 wide', (
      tester,
    ) async {
      await _openEditProfile(
        tester,
        size: const Size(320, 568),
        locale: locale,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
