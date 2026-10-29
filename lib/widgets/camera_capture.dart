import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_colors.dart';
import '../core/localization/generated/app_localizations.dart';
import 'pill_button.dart';

/// Takes a photo with the device camera, or returns null if cancelled.
///
/// Phones open their own camera app (via image_picker). Browsers and
/// desktops can't do that — a desktop browser would only show a file
/// chooser — so they get [CameraCaptureScreen] with a live preview instead.
Future<XFile?> takePhoto(
  BuildContext context, {
  double? maxWidth,
  double? maxHeight,
  int imageQuality = 85,
}) {
  final hasCameraApp = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (hasCameraApp) {
    return ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }
  return Navigator.of(context).push<XFile>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const CameraCaptureScreen(),
    ),
  );
}

enum _CameraProblem { notFound, permissionDenied, failed }

/// Full-screen camera: live preview and shutter, then Retake / Use photo.
/// Pops with the taken photo, or null when closed.
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key, this.loadCameras = availableCameras});

  /// Lists the device's cameras (replaceable in tests).
  final Future<List<CameraDescription>> Function() loadCameras;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  CameraController? _controller;
  _CameraProblem? _problem;
  bool _capturing = false;

  XFile? _photo;
  Uint8List? _photoBytes;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final List<CameraDescription> cameras;
    try {
      cameras = await widget.loadCameras();
    } on CameraException catch (e) {
      _fail(e);
      return;
    }
    if (!mounted) return;
    if (cameras.isEmpty) {
      setState(() => _problem = _CameraProblem.notFound);
      return;
    }
    // Items are photographed with the back camera when there is one.
    final back = cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    _cameras = cameras;
    _cameraIndex = back == -1 ? 0 : back;
    await _open(cameras[_cameraIndex]);
  }

  Future<void> _open(CameraDescription camera) async {
    final previous = _controller;
    setState(() {
      _controller = null;
      _problem = null;
    });
    await previous?.dispose();

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await controller.initialize();
    } on CameraException catch (e) {
      await controller.dispose();
      _fail(e);
      return;
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);
  }

  void _fail(CameraException error) {
    if (!mounted) return;
    // Codes differ per platform (e.g. CameraAccessDenied, cameraPermission,
    // NotAllowedError), so match on their wording.
    final code = error.code.toLowerCase();
    final problem = code.contains('denied') ||
            code.contains('permission') ||
            code.contains('notallowed')
        ? _CameraProblem.permissionDenied
        : code.contains('notfound')
            ? _CameraProblem.notFound
            : _CameraProblem.failed;
    setState(() => _problem = problem);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      final photo = await controller.takePicture();
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photo = photo;
        _photoBytes = bytes;
      });
    } on CameraException catch (e) {
      _fail(e);
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _switchCamera() {
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    _open(_cameras[_cameraIndex]);
  }

  void _retake() => setState(() {
        _photo = null;
        _photoBytes = null;
      });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close, color: AppColors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(child: _buildViewport(l10n)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _photoBytes != null
                    ? _buildReviewActions(l10n)
                    : _buildShutterRow(l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewport(AppLocalizations l10n) {
    if (_photoBytes case final bytes?) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.memory(bytes, fit: BoxFit.contain),
      );
    }
    if (_problem case final problem?) {
      final message = switch (problem) {
        _CameraProblem.notFound => l10n.cameraNotFound,
        _CameraProblem.permissionDenied => l10n.cameraPermissionDenied,
        _CameraProblem.failed => l10n.cameraFailed,
      };
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 56,
              color: AppColors.white,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.white,
                  ),
            ),
          ],
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const CircularProgressIndicator(color: AppColors.white);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: controller.buildPreview(),
      ),
    );
  }

  Widget _buildShutterRow(AppLocalizations l10n) {
    final ready = _controller?.value.isInitialized ?? false;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Balances the switch button so the shutter stays centred.
        const SizedBox(width: 48),
        _ShutterButton(
          tooltip: l10n.cameraCapture,
          onPressed: ready && !_capturing ? _capture : null,
        ),
        SizedBox(
          width: 48,
          child: _cameras.length > 1 && _problem == null
              ? IconButton(
                  onPressed: ready && !_capturing ? _switchCamera : null,
                  tooltip: l10n.cameraSwitch,
                  icon: const Icon(
                    Icons.cameraswitch_outlined,
                    color: AppColors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.white.withValues(alpha: 0.12),
                  ),
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildReviewActions(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _retake,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.white,
              minimumSize: const Size.fromHeight(54),
              side: const BorderSide(color: AppColors.white, width: 1.5),
              shape: const StadiumBorder(),
              textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            child: Text(l10n.cameraRetake),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PillButton(
            label: l10n.cameraUsePhoto,
            onPressed: () => Navigator.of(context).pop(_photo),
          ),
        ),
      ],
    );
  }
}

/// Round white shutter: a ring around a filled circle.
class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 4),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: enabled ? 1 : 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
