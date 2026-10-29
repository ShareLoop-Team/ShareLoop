import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'item_photo.dart';

/// Opens [urls] full screen at [initialIndex], with pinch and double-tap
/// zoom and swiping between photos.
void showPhotoViewer(
  BuildContext context, {
  required List<String> urls,
  int initialIndex = 0,
}) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 200),
      reverseTransitionDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) =>
          PhotoViewer(urls: urls, initialIndex: initialIndex),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Full-screen black photo pager. Swiping between photos is paused while a
/// photo is zoomed, so dragging pans the zoomed photo instead.
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.urls, this.initialIndex = 0});

  final List<String> urls;
  final int initialIndex;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final PageController _pageController;
  late int _page;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _page = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.urls.length;
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: _zoomed
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            itemCount: count,
            onPageChanged: (page) => setState(() {
              _page = page;
              _zoomed = false;
            }),
            itemBuilder: (context, index) => _ZoomablePhoto(
              url: widget.urls[index],
              onZoomChanged: (zoomed) {
                if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    icon: const Icon(Icons.close, color: AppColors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.black.withValues(alpha: 0.4),
                    ),
                  ),
                  const Spacer(),
                  if (count > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_page + 1} / $count',
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: AppColors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One photo with pinch zoom (up to 4x) and double-tap to zoom in/out.
class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({required this.url, required this.onZoomChanged});

  final String url;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto>
    with SingleTickerProviderStateMixin {
  static const double _doubleTapScale = 2.5;

  final _transform = TransformationController();
  late final AnimationController _animation;
  Animation<Matrix4>? _zoomAnimation;
  Offset _doubleTapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() => _transform.value = _zoomAnimation!.value);
    _transform.addListener(_reportZoom);
  }

  @override
  void dispose() {
    _transform.removeListener(_reportZoom);
    _transform.dispose();
    _animation.dispose();
    super.dispose();
  }

  void _reportZoom() =>
      widget.onZoomChanged(_transform.value.getMaxScaleOnAxis() > 1.01);

  void _toggleZoom() {
    final Matrix4 target;
    if (_transform.value.getMaxScaleOnAxis() > 1.01) {
      target = Matrix4.identity();
    } else {
      // Zoom in around the tapped point.
      final p = _doubleTapPosition;
      target = Matrix4.identity()
        ..translateByDouble(
          -p.dx * (_doubleTapScale - 1),
          -p.dy * (_doubleTapScale - 1),
          0,
          1,
        )
        ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1);
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _transform.value = target;
      return;
    }
    _zoomAnimation = Matrix4Tween(begin: _transform.value, end: target)
        .animate(CurvedAnimation(parent: _animation, curve: Curves.easeOut));
    _animation.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapPosition = details.localPosition,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _transform,
        maxScale: 4,
        child: SizedBox.expand(
          child: ItemPhoto(
            url: widget.url,
            fit: BoxFit.contain,
            placeholder: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 64,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
