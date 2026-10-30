import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/widgets/avatar_crop_screen.dart';

const _red = Color(0xFFFF0000);
const _blue = Color(0xFF0000FF);

/// A 200x100 PNG: left half red, right half blue.
Future<Uint8List> _twoColourPng() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder)
    ..drawRect(const Rect.fromLTWH(0, 0, 100, 100), Paint()..color = _red)
    ..drawRect(const Rect.fromLTWH(100, 0, 100, 100), Paint()..color = _blue);
  final image = await recorder.endRecording().toImage(200, 100);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// RGBA of the pixel at ([x], [y]) in the PNG [bytes].
Future<Color> _pixel(Uint8List bytes, int x, int y) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final image = (await codec.getNextFrame()).image;
  final rgba = (await image.toByteData())!;
  final i = (y * image.width + x) * 4;
  return Color.fromARGB(
    rgba.getUint8(i + 3),
    rgba.getUint8(i),
    rgba.getUint8(i + 1),
    rgba.getUint8(i + 2),
  );
}

/// Opens the cropper on [bytes]; [results] receives what it returns.
Future<void> _open(
  WidgetTester tester,
  Uint8List bytes,
  List<Uint8List?> results,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => results.add(await cropAvatar(context, bytes)),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  // The spinner animates until decoding (real async work) has finished.
  await tester.pump(const Duration(milliseconds: 500));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pumpAndSettle();
}

Future<void> _usePhoto(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(find.text('Use photo'));
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await tester.pumpAndSettle();
}

void main() {
  late Uint8List png;
  setUpAll(() async => png = await _twoColourPng());

  testWidgets('crops the centred square by default', (tester) async {
    final results = <Uint8List?>[];
    await _open(tester, png, results);

    expect(find.text('Adjust photo'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    await _usePhoto(tester);

    expect(results, hasLength(1));
    final cropped = results.single!;
    await tester.runAsync(() async {
      const size = AvatarCropScreen.outputSize;
      expect(await _pixel(cropped, size ~/ 4, size ~/ 2), _red);
      expect(await _pixel(cropped, size * 3 ~/ 4, size ~/ 2), _blue);
    });
  });

  testWidgets('dragging moves the crop, but never past the photo edge', (
    tester,
  ) async {
    final results = <Uint8List?>[];
    await _open(tester, png, results);

    // Far further than the photo's overflow: it stops at its left edge.
    await tester.drag(find.byType(RawImage), const Offset(1000, 0));
    await tester.pumpAndSettle();
    await _usePhoto(tester);

    await tester.runAsync(() async {
      const size = AvatarCropScreen.outputSize;
      expect(await _pixel(results.single!, size - 8, size ~/ 2), _red);
    });
  });

  testWidgets('cancel returns nothing', (tester) async {
    final results = <Uint8List?>[];
    await _open(tester, png, results);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(results, [null]);
  });
}
