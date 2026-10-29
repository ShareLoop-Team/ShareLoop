import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:shareloop/core/constants/app_colors.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/widgets/camera_capture.dart';
import 'package:shareloop/widgets/photo_source_sheet.dart';

Widget _app(Widget home, {ThemeMode themeMode = ThemeMode.light}) {
  return MaterialApp(
    themeMode: themeMode,
    darkTheme: ThemeData.dark(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
    home: home,
  );
}

/// A button that opens [CameraCaptureScreen] and records what it returned.
class _Opener extends StatelessWidget {
  const _Opener({required this.loadCameras, required this.onResult});

  final Future<List<CameraDescription>> Function() loadCameras;
  final ValueChanged<XFile?> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () async => onResult(
          await Navigator.of(context).push<XFile>(
            MaterialPageRoute(
              builder: (_) => CameraCaptureScreen(loadCameras: loadCameras),
            ),
          ),
        ),
        child: const Text('open'),
      ),
    );
  }
}

void main() {
  testWidgets('says so when the device has no camera, and closes empty', (
    tester,
  ) async {
    var closed = false;
    XFile? result;
    await tester.pumpWidget(
      _app(
        _Opener(
          loadCameras: () async => const [],
          onResult: (file) {
            closed = true;
            result = file;
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('No camera found on this device.'), findsOneWidget);
    expect(find.byIcon(Icons.no_photography_outlined), findsOneWidget);
    expect(find.byTooltip('Switch camera'), findsNothing);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('explains a blocked camera permission', (tester) async {
    await tester.pumpWidget(
      _app(
        CameraCaptureScreen(
          loadCameras: () async =>
              throw CameraException('CameraAccessDenied', 'denied'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Camera access is blocked'), findsOneWidget);
  });

  testWidgets('other camera errors show a generic message', (tester) async {
    await tester.pumpWidget(
      _app(
        CameraCaptureScreen(
          loadCameras: () async => throw CameraException('unknown', 'boom'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text("Couldn't start the camera. Please try again."),
      findsOneWidget,
    );
  });

  testWidgets('photo sheet stays readable in dark mode and returns the '
      'chosen source', (tester) async {
    ImageSource? chosen;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  chosen = await showPhotoSourceSheet(context),
              child: const Text('pick'),
            ),
          ),
        ),
        themeMode: ThemeMode.dark,
      ),
    );
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();

    final label = tester.widget<RichText>(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == 'Take a photo',
      ),
    );
    expect(label.text.style?.color, AppColors.ink);

    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(chosen, ImageSource.camera);
  });
}
