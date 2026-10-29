import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../core/localization/generated/app_localizations.dart';
import 'pill_button.dart';

/// Lets the user frame [bytes] inside a round profile-photo crop. Returns
/// the cropped square as PNG bytes, or null when cancelled.
Future<Uint8List?> cropAvatar(BuildContext context, Uint8List bytes) {
  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AvatarCropScreen(bytes: bytes),
    ),
  );
}

/// Full-screen cropper: drag to move, pinch / scroll / slider to zoom. The
/// photo always covers the round frame, so the result has no empty edges.
class AvatarCropScreen extends StatefulWidget {
  const AvatarCropScreen({super.key, required this.bytes});

  final Uint8List bytes;

  /// Width and height of the cropped photo, in pixels.
  static const int outputSize = 512;

  static const double maxZoom = 4;

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  ui.Image? _image;
  bool _failed = false;
  bool _saving = false;

  /// Side of the square crop frame on screen; set by the layout.
  double _frame = 0;

  /// 1 = the photo just covers the frame.
  double _zoom = 1;

  /// Top-left of the photo relative to the frame, in screen pixels.
  Offset _offset = Offset.zero;

  double _gestureStartZoom = 1;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _decode() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  /// Screen pixels per photo pixel at the current zoom.
  double get _scale {
    final image = _image!;
    return _frame / math.min(image.width, image.height) * _zoom;
  }

  Size get _displaySize =>
      Size(_image!.width * _scale, _image!.height * _scale);

  /// Keeps the photo covering the whole frame.
  Offset _clamp(Offset offset) {
    final size = _displaySize;
    return Offset(
      offset.dx.clamp(_frame - size.width, 0),
      offset.dy.clamp(_frame - size.height, 0),
    );
  }

  void _setFrame(double frame) {
    if (frame == _frame) return;
    final wasLaidOut = _frame > 0;
    final previous = _frame;
    _frame = frame;
    if (!wasLaidOut) {
      // Start centred.
      final size = _displaySize;
      _offset = Offset(
        (frame - size.width) / 2,
        (frame - size.height) / 2,
      );
    } else {
      _offset = _clamp(_offset * (frame / previous));
    }
  }

  /// Changes the zoom while keeping the photo point under [focal] still.
  void _zoomTo(double zoom, Offset focal) {
    final next = zoom.clamp(1.0, AvatarCropScreen.maxZoom);
    final ratio = next / _zoom;
    setState(() {
      _zoom = next;
      _offset = _clamp(focal - (focal - _offset) * ratio);
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount > 1) {
      _zoomTo(_gestureStartZoom * details.scale, details.localFocalPoint);
    }
    setState(() => _offset = _clamp(_offset + details.focalPointDelta));
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _zoomTo(_zoom * math.exp(-event.scrollDelta.dy / 400), event.localPosition);
    }
  }

  Future<void> _save() async {
    final image = _image;
    if (image == null || _saving) return;
    setState(() => _saving = true);

    // The part of the photo inside the frame, in photo pixels.
    final scale = _scale;
    final source = Rect.fromLTWH(
      -_offset.dx / scale,
      -_offset.dy / scale,
      _frame / scale,
      _frame / scale,
    );
    const size = AvatarCropScreen.outputSize;
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      image,
      source,
      const Rect.fromLTWH(0, 0, size + 0.0, size + 0.0),
      Paint()..filterQuality = FilterQuality.high,
    );
    final picture = recorder.endRecording();
    final cropped = await picture.toImage(size, size);
    picture.dispose();
    final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
    cropped.dispose();
    if (!mounted) return;
    Navigator.of(context).pop(data!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: const Icon(Icons.close, color: AppColors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.cropTitle,
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              // The dimmed photo around the frame stays inside this area.
              child: ClipRect(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: _buildCropArea(l10n)),
                ),
              ),
            ),
            if (_image != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l10n.cropHint,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.zoom_out, color: AppColors.white),
                      Expanded(
                        child: Slider(
                          value: _zoom,
                          min: 1,
                          max: AvatarCropScreen.maxZoom,
                          label: l10n.cropZoom,
                          semanticFormatterCallback: (value) =>
                              '${l10n.cropZoom} ${value.toStringAsFixed(1)}x',
                          activeColor: AppColors.white,
                          inactiveColor: AppColors.white.withValues(alpha: 0.3),
                          onChanged: (value) =>
                              _zoomTo(value, Offset(_frame / 2, _frame / 2)),
                        ),
                      ),
                      const Icon(Icons.zoom_in, color: AppColors.white),
                    ],
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white,
                          minimumSize: const Size.fromHeight(54),
                          side: const BorderSide(
                            color: AppColors.white,
                            width: 1.5,
                          ),
                          shape: const StadiumBorder(),
                          textStyle: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(
                          MaterialLocalizations.of(context).cancelButtonLabel,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PillButton(
                        label: l10n.cameraUsePhoto,
                        isLoading: _saving,
                        onPressed: _image == null ? null : _save,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropArea(AppLocalizations l10n) {
    if (_failed) {
      return Text(
        l10n.cameraFailed,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.white),
      );
    }
    final image = _image;
    if (image == null) {
      return const CircularProgressIndicator(color: AppColors.white);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        _setFrame(
          math.min(math.min(constraints.maxWidth, constraints.maxHeight), 420),
        );
        final size = _displaySize;
        return Listener(
          onPointerSignal: _onPointerSignal,
          child: GestureDetector(
            onScaleStart: (_) => _gestureStartZoom = _zoom,
            onScaleUpdate: _onScaleUpdate,
            child: SizedBox.square(
              dimension: _frame,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: _offset.dx,
                    top: _offset.dy,
                    width: size.width,
                    height: size.height,
                    child: RawImage(
                      image: image,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _CircleMaskPainter()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dims everything outside the round frame and outlines the circle.
class _CircleMaskPainter extends CustomPainter {
  const _CircleMaskPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final circle = Rect.fromLTWH(0, 0, size.width, size.height);
    // Reaches past the frame so the photo's overflow is dimmed too.
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(circle.inflate(2000))
      ..addOval(circle);
    canvas.drawPath(
      outside,
      Paint()..color = AppColors.black.withValues(alpha: 0.6),
    );
    canvas.drawOval(
      circle.deflate(1),
      Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_CircleMaskPainter oldDelegate) => false;
}
