import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/splash_controller.dart';
import '../../core/constants/app_colors.dart';

/// View: branded launch screen. Animates the logo in, then hands off to
/// [SplashController] to restore any session and decide the next route.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Longest wait for the engine to report the first rasterized frame.
  static const Duration _firstFrameTimeout = Duration(seconds: 3);

  final _splashController = SplashController();
  late final AnimationController _animationController;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _progressOpacity;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoOpacity = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _progressOpacity = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
    );
    _start();
  }

  /// Begins the logo animation and the splash timer once the first frame has
  /// really reached the screen. Until then the native splash (same color) is
  /// still showing, so counting earlier would let a slow first frame use up
  /// the minimum display time before the logo ever appears. The wait is capped
  /// so the splash can never hang if the engine does not report the frame.
  Future<void> _start() async {
    final binding = WidgetsBinding.instance;
    if (!binding.firstFrameRasterized) {
      await binding.waitUntilFirstFrameRasterized.timeout(
        _firstFrameTimeout,
        onTimeout: () {},
      );
    }
    if (!mounted) return;
    _animationController.forward();
    await _navigate();
  }

  Future<void> _navigate() async {
    final auth = context.read<AuthController>();
    final nextRoute = await _splashController.resolveNextRoute(auth);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always light, even in dark mode: dark status-bar icons keep the system
    // bars legible on the canvas background.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  // The wordmark asset is cropped tight to the artwork, so this
                  // is the visible logo width: 55% of the screen, capped so it
                  // is never upscaled far beyond the asset's 606 px on tablets.
                  child: SizedBox(
                    width: math.min(
                      MediaQuery.sizeOf(context).width * 0.55,
                      320,
                    ),
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: child,
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/images/shareloop_wordmark.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              FadeTransition(
                opacity: _progressOpacity,
                child: Container(
                  width: 120,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    color: AppColors.softMint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const _IndeterminateProgressBar(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin looping progress indicator drawn in brand colors, used in place of
/// the default [LinearProgressIndicator] to control its track/value colors.
class _IndeterminateProgressBar extends StatefulWidget {
  const _IndeterminateProgressBar();

  @override
  State<_IndeterminateProgressBar> createState() =>
      _IndeterminateProgressBarState();
}

class _IndeterminateProgressBarState extends State<_IndeterminateProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth * 0.4;
              final travel = constraints.maxWidth - width;
              final x = travel * Curves.easeInOut.transform(_controller.value);
              return Stack(
                children: [
                  Positioned(
                    left: x,
                    child: Container(
                      width: width,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.brightGreen,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
