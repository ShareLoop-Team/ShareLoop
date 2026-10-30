import 'package:flutter/material.dart';

import '../../core/theme/sl_tokens.dart';

/// Shrinks [child] slightly while pressed, so a tap feels physical. Off
/// when the system asks to reduce motion.
class SLPressScale extends StatefulWidget {
  const SLPressScale({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<SLPressScale> createState() => _SLPressScaleState();
}

class _SLPressScaleState extends State<SLPressScale> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || SLMotion.reduced(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: SLMotion.press,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// A slow fade in and out on loading placeholders, so a slow load reads as
/// "working", not frozen. Not a shimmer: nothing sweeps across. Still when
/// the system asks to reduce motion.
class SLLoadingPulse extends StatefulWidget {
  const SLLoadingPulse({super.key, required this.child, this.label});

  final Widget child;

  /// Read by screen readers, e.g. "Loading".
  final String? label;

  @override
  State<SLLoadingPulse> createState() => _SLLoadingPulseState();
}

class _SLLoadingPulseState extends State<SLLoadingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.55,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SLMotion.reduced(context)) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: FadeTransition(opacity: _controller, child: widget.child),
      ),
    );
  }
}

/// Fades [child] in while it rises 16px, once, when first built. [index]
/// staggers items that appear together (capped, so long lists don't wait).
/// Shown at once when the system asks to reduce motion.
class SLFadeIn extends StatefulWidget {
  const SLFadeIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<SLFadeIn> createState() => _SLFadeInState();
}

class _SLFadeInState extends State<SLFadeIn>
    with SingleTickerProviderStateMixin {
  static const int _maxStaggered = 6;

  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final delay = SLMotion.stagger * widget.index.clamp(0, _maxStaggered);
    final total = delay + SLMotion.enter;
    _controller = AnimationController(vsync: this, duration: total);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SLMotion.reduced(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) => Opacity(
        opacity: _progress.value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - _progress.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
