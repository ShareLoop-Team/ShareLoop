import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:provider/provider.dart';

import 'package:shareloop/controllers/auth_controller.dart';
import 'package:shareloop/controllers/item_controller.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/services/photo_check/photo_content_checker.dart';
import 'package:shareloop/views/give_away/create_give_away_screen.dart';

const _personMessage = 'This photo contains a person or a visible body part. '
    'Please upload a photo of the item only.';
const _failedMessage = "We couldn't check this photo, so it wasn't added. "
    'Please try again or choose another photo.';

/// Gallery that "picks" the given photos.
class _FakeGallery extends ImagePickerPlatform {
  _FakeGallery(this.files);

  final List<XFile> files;

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async =>
      files;
}

/// Answers with [outcomes] in order, one per checked photo.
class _ScriptedChecker implements PhotoContentChecker {
  _ScriptedChecker(this.outcomes);

  final List<PhotoCheckOutcome> outcomes;
  int checked = 0;

  @override
  Future<PhotoCheckOutcome> check(Uint8List bytes, {String? mimeType}) async =>
      outcomes[checked++];
}

XFile _photo(String asset) => XFile.fromData(
      File('assets/images/$asset').readAsBytesSync(),
      mimeType: 'image/jpeg',
      name: asset,
    );

Future<void> _pickPhotos(
  WidgetTester tester, {
  required List<XFile> files,
  required PhotoContentChecker checker,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  ImagePickerPlatform.instance = _FakeGallery(files);

  final auth = AuthController();
  await tester.runAsync(() => auth.login('nimal@example.com', 'x'));
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => ItemController()),
        Provider<PhotoContentChecker>.value(value: checker),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('si'), Locale('ta')],
        home: CreateGiveAwayScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Add photos of your item'));
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(find.text('Choose from gallery'));
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await tester.pumpAndSettle();
}

/// Thumbnails of the photos the form accepted.
Finder get _thumbnails => find.byWidgetPredicate(
      (w) => w is Image && w.image is MemoryImage,
    );

void main() {
  testWidgets('of three photos, the one with a person is left out', (
    tester,
  ) async {
    final checker = _ScriptedChecker([
      PhotoCheckOutcome.clear,
      PhotoCheckOutcome.containsPerson,
      PhotoCheckOutcome.clear,
    ]);
    await _pickPhotos(
      tester,
      files: [
        _photo('item_grade10_science.jpg'),
        _photo('login_hero.jpg'),
        _photo('item_smartphone.jpg'),
      ],
      checker: checker,
    );

    expect(checker.checked, 3);
    expect(_thumbnails, findsNWidgets(2));
    expect(find.text('2/3'), findsOneWidget);
    expect(find.text(_personMessage), findsOneWidget);
  });

  testWidgets('a photo that cannot be checked is not added', (tester) async {
    await _pickPhotos(
      tester,
      files: [_photo('item_grade10_science.jpg')],
      checker: _ScriptedChecker([PhotoCheckOutcome.failed]),
    );

    expect(_thumbnails, findsNothing);
    expect(find.text('0/3'), findsOneWidget);
    expect(find.text(_failedMessage), findsOneWidget);
    // The user can simply try again.
    expect(find.text('Add photos of your item'), findsOneWidget);
  });

  testWidgets('a device without a detector says so and adds nothing', (
    tester,
  ) async {
    await _pickPhotos(
      tester,
      files: [_photo('item_grade10_science.jpg')],
      checker: const UnsupportedPhotoChecker(),
    );

    expect(_thumbnails, findsNothing);
    expect(
      find.textContaining("Photos can't be checked on this device"),
      findsOneWidget,
    );
  });

  testWidgets('cleared photos are added with no warning', (tester) async {
    await _pickPhotos(
      tester,
      files: [_photo('item_grade10_science.jpg'), _photo('item_smartphone.jpg')],
      checker: _ScriptedChecker([
        PhotoCheckOutcome.clear,
        PhotoCheckOutcome.clear,
      ]),
    );

    expect(_thumbnails, findsNWidgets(2));
    expect(find.byType(SnackBar), findsNothing);
  });
}
