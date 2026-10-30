import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shareloop/controllers/auth_controller.dart';
import 'package:shareloop/controllers/language_controller.dart';
import 'package:shareloop/core/routes/app_routes.dart';
import 'package:shareloop/core/theme/app_theme.dart';
import 'package:shareloop/main.dart';
import 'package:shareloop/widgets/app_icon.dart';

/// Widget tests draw text with a placeholder font, which hides real glyph
/// widths. Loading the bundled fonts makes layout (and overflow) real.
Future<void> _loadBundledFonts() async {
  const families = {
    'Inter': ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'],
    'NotoSansSinhala': ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'],
  };
  for (final MapEntry(key: family, value: weights) in families.entries) {
    final loader = FontLoader(family);
    for (final weight in weights) {
      final bytes = File('assets/fonts/$family-$weight.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

double _width(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

void main() {
  setUpAll(_loadBundledFonts);

  test('theme uses Inter with the agreed type scale', () {
    final text = AppTheme.lightTheme.textTheme;
    expect(text.bodyMedium!.fontFamily, 'Inter');
    expect(text.bodyMedium!.fontFamilyFallback, [
      'NotoSansSinhala',
      'NotoSansTamil',
    ]);
    expect(text.headlineSmall!.fontSize, 26);
    expect(text.titleLarge!.fontSize, 20);
    expect(text.titleMedium!.fontSize, 16);
    expect(text.bodyLarge!.fontSize, 16);
    expect(text.bodyMedium!.fontSize, 14);
    expect(text.labelLarge!.fontSize, 14);
    expect(text.labelMedium!.fontSize, 12);
    expect(AppTheme.darkTheme.textTheme.bodyMedium!.fontFamily, 'Inter');
  });

  testWidgets('Sinhala text falls back to Noto Sans Sinhala', (tester) async {
    // Letters only: spaces and punctuation exist in Inter, so it draws them.
    const sinhala = 'කුමක්බෙදාගන්නවාද';
    final body = AppTheme.lightTheme.textTheme.bodyMedium!;

    final viaFallback = _width(sinhala, body);
    final viaNoto = _width(
      sinhala,
      body.copyWith(fontFamily: 'NotoSansSinhala', fontFamilyFallback: []),
    );
    final withoutFallback = _width(
      sinhala,
      body.copyWith(fontFamilyFallback: []),
    );

    expect(viaFallback, closeTo(viaNoto, 0.01));
    // Without the fallback the glyphs come from the test placeholder font.
    expect(withoutFallback, isNot(closeTo(viaNoto, 0.01)));
  });

  for (final code in const ['en', 'si']) {
    testWidgets('main screens fit 320px with real fonts in $code', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ShareLoopApp());
      final appContext = tester.element(find.byType(MaterialApp));
      appContext.read<LanguageController>().setLanguage(code);
      // Splash, then the intro pages.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'intro');

      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      Future<void> open(String route, {Object? arguments}) async {
        navigator.pushNamed(route, arguments: arguments);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: route);
      }

      await open(AppRoutes.onboarding);
      await open(AppRoutes.login);
      await open(AppRoutes.register);

      await tester.runAsync(
        () => appContext.read<AuthController>().login('nimal@example.com', 'x'),
      );
      navigator.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 600)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'home');

      for (final glyph in const [
        AppGlyph.give,
        AppGlyph.requests,
        AppGlyph.profile,
      ]) {
        await tester.tap(
          find.byWidgetPredicate((w) => w is AppIcon && w.glyph == glyph),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 600)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: glyph.name);
      }

      await open(AppRoutes.editProfile);
      await open(AppRoutes.itemDetails, arguments: 'p1');
      await open(AppRoutes.myDonations);
      await open(AppRoutes.myRequests);
      await open(AppRoutes.myReviews);
      await open(AppRoutes.createRequest);
    });
  }
}
