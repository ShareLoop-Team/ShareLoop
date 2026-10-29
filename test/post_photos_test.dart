import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shareloop/controllers/item_controller.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/models/photo_upload.dart';
import 'package:shareloop/services/mock_data_service.dart';
import 'package:shareloop/widgets/item_grid_card.dart';

void main() {
  testWidgets('a published post shows its photo on the Home card', (
    tester,
  ) async {
    final bytes = Uint8List.fromList(
      File('assets/images/item_grey_cap.jpg').readAsBytesSync(),
    );
    final items = ItemController();
    await tester.runAsync(() async {
      final error = await items.createPost(
        donorId: 'u-photo-test',
        donorName: 'Photo Tester',
        title: 'Desk lamp',
        description: 'Works well',
        condition: 'Good',
        category: 'Household Items',
        district: 'Kandy',
        city: 'Kandy',
        photos: [
          PhotoUpload(bytes: bytes, mimeType: 'image/jpeg', name: 'lamp.jpg'),
        ],
      );
      expect(error, isNull);
    });
    addTearDown(
      () => MockDataService.instance.itemPosts.removeWhere(
        (p) => p.donorId == 'u-photo-test',
      ),
    );

    final post = items.postsByDonor('u-photo-test').single;
    expect(post.photoUrls, hasLength(1));
    expect(post.photoUrls.single, startsWith('data:image/jpeg;base64,'));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 260,
            child: ItemGridCard(post: post, donorBadge: null, onTap: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The picked photo, not the empty image placeholder.
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is MemoryImage),
      findsOneWidget,
    );
  });
}
