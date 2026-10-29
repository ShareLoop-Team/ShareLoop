import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shareloop/controllers/profile_controller.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/models/photo_upload.dart';
import 'package:shareloop/views/profile/edit_profile_screen.dart';
import 'package:shareloop/widgets/user_avatar.dart';

/// Opens Edit Profile for mock user u4 (Priya) on top of a stand-in page,
/// so saving can pop back to it.
Future<ProfileController> _openEditProfile(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final profile = ProfileController();
  await tester.runAsync(() => profile.loadProfile('u4'));

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: profile,
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
  return profile;
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
    final profile = await _openEditProfile(tester);

    await tester.enterText(_fieldWithText('Priya Rajan'), 'Priya R.');
    await tester.runAsync(() async {
      await tester.tap(find.text('Save Changes'));
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pumpAndSettle();

    expect(profile.user?.name, 'Priya R.');
    expect(find.byType(EditProfileScreen), findsNothing);
    expect(find.text('Profile updated.'), findsOneWidget);
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
