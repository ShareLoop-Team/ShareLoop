import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shareloop/controllers/auth_controller.dart';
import 'package:shareloop/controllers/splash_controller.dart';
import 'package:shareloop/core/constants/app_colors.dart';
import 'package:shareloop/core/routes/app_routes.dart';
import 'package:shareloop/main.dart';
import 'package:shareloop/views/onboarding/intro_screen.dart';
import 'package:shareloop/views/splash/splash_screen.dart';

/// [AuthController] whose session restoration takes [initDuration] and can
/// be made to fail.
class _FakeAuthController extends AuthController {
  _FakeAuthController(this.initDuration, {this.fail = false});

  final Duration initDuration;
  final bool fail;

  @override
  Future<void> restoreSession() async {
    await Future<void>.delayed(initDuration);
    if (fail) throw StateError('restore failed');
  }
}

void main() {
  // flutter_test never rasterizes frames, so WidgetsBinding.firstFrameRasterized
  // stays false and the splash falls back to its 3 s first-frame ceiling. The
  // raster-triggered path is verified on a real device/emulator instead.
  const firstFrameCeiling = Duration(seconds: 3);

  testWidgets('does not start the animation or clock before the first frame '
      'is reported, then shows the logo for about one second', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ShareLoopApp());

    // Still waiting for the first frame: neither the logo animation nor the
    // minimum-display timer has started, so nothing can navigate away.
    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(IntroScreen), findsNothing);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);

    await tester.pump(firstFrameCeiling - const Duration(milliseconds: 2500));
    await tester.pump(); // First animation frame; the clock started above.
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.byType(IntroScreen), findsOneWidget);
  });
  group('SplashController minimum duration', () {
    testWidgets('waits the full minimum when initialization is instant', (
      tester,
    ) async {
      String? route;
      SplashController()
          .resolveNextRoute(_FakeAuthController(Duration.zero))
          .then((value) => route = value);

      await tester.pump(const Duration(milliseconds: 900));
      expect(route, isNull);

      await tester.pump(const Duration(milliseconds: 100));
      expect(route, AppRoutes.intro);
    });

    testWidgets('does not add the minimum on top of slow initialization', (
      tester,
    ) async {
      String? route;
      SplashController()
          .resolveNextRoute(
            _FakeAuthController(const Duration(milliseconds: 1800)),
          )
          .then((value) => route = value);

      await tester.pump(const Duration(milliseconds: 1700));
      expect(route, isNull, reason: 'must wait for initialization');

      // Init ends at 1800 ms; a second delay stacked after it would still be
      // pending here.
      await tester.pump(const Duration(milliseconds: 100));
      expect(route, AppRoutes.intro);
    });

    testWidgets('still routes to the intro, and reports, if init fails', (
      tester,
    ) async {
      String? route;
      SplashController()
          .resolveNextRoute(_FakeAuthController(Duration.zero, fail: true))
          .then((value) => route = value);

      await tester.pump(const Duration(seconds: 1));

      expect(route, AppRoutes.intro);
      expect(tester.takeException(), isA<StateError>());
    });
  });

  group('SplashScreen', () {
    Future<void> openSplash(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const ShareLoopApp());
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('shows only the wordmark: no version label or tagline', (
      tester,
    ) async {
      await openSplash(tester);

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.textContaining('Version'), findsNothing);
      expect(find.textContaining('Share more'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName ==
                  'assets/images/shareloop_wordmark.png',
        ),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    for (final brightness in Brightness.values) {
      testWidgets('uses the canvas background in ${brightness.name} mode', (
        tester,
      ) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await openSplash(tester);

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, AppColors.canvas);
        expect(AppColors.canvas, const Color(0xFFF7FAF6));

        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      });
    }

    testWidgets('navigates to the intro about one second after the clock '
        'starts', (tester) async {
      await openSplash(tester);

      // The clock starts when the first-frame wait ends (the ceiling here).
      await tester.pump(firstFrameCeiling);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byType(IntroScreen), findsOneWidget);
    });
  });
}
