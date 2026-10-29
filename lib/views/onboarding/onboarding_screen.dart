import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controllers/onboarding_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/app_theme.dart';

/// View: welcome/onboarding screen shown after the splash. Log in and Register
/// are handled by [OnboardingController]; both keep this screen on the back
/// stack.
///
/// Always uses the light brand theme (canvas background, deep-green button)
/// so it matches the design even when the device is in dark mode.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(data: AppTheme.lightTheme, child: const _OnboardingBody());
  }
}

class _OnboardingBody extends StatefulWidget {
  const _OnboardingBody();

  @override
  State<_OnboardingBody> createState() => _OnboardingBodyState();
}

class _OnboardingBodyState extends State<_OnboardingBody>
    with SingleTickerProviderStateMixin {
  static const String _illustrationAsset =
      'assets/images/Onboarding screen design.png';
  static const String _wordmarkAsset = 'assets/images/shareloop_wordmark.png';

  final _controller = const OnboardingController();
  late final AnimationController _animationController;
  late final Animation<double> _illustrationOpacity;
  late final Animation<Offset> _illustrationOffset;
  late final Animation<double> _contentOpacity;
  late final Animation<double> _actionsOpacity;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _illustrationOpacity = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );
    _illustrationOffset = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_illustrationOpacity);
    _contentOpacity = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.25, 0.8, curve: Curves.easeOutCubic),
    );
    _actionsOpacity = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Skip the fade when the user has asked the OS to reduce motion.
    if (MediaQuery.disableAnimationsOf(context)) {
      _animationController.value = 1;
    } else if (_animationController.isDismissed) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The illustration grows with the screen but never takes more than
            // ~42% of the height, so the logo, text and buttons always fit on
            // a 360x800 phone without scrolling.
            final contentWidth = math.min(constraints.maxWidth - 48, 480.0);
            final illustrationWidth = math.min(
              contentWidth,
              constraints.maxHeight * 0.42 * _Illustration.aspectRatio,
            );
            final wordmarkWidth = math.min(contentWidth * 0.55, 220.0);

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(),
                          const SizedBox(height: 24),
                          FadeTransition(
                            opacity: _illustrationOpacity,
                            child: SlideTransition(
                              position: _illustrationOffset,
                              child: _Illustration(
                                asset: _illustrationAsset,
                                width: illustrationWidth,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          FadeTransition(
                            opacity: _contentOpacity,
                            child: Column(
                              children: [
                                Semantics(
                                  header: true,
                                  label: l10n.appTitle,
                                  child: ExcludeSemantics(
                                    child: Image.asset(
                                      _wordmarkAsset,
                                      width: wordmarkWidth,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.onboardingDescription,
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 32),
                          FadeTransition(
                            opacity: _actionsOpacity,
                            child: _GetStartedButton(
                              label: l10n.onboardingGetStarted,
                              onPressed: () =>
                                  _controller.getStarted(Navigator.of(context)),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Hero illustration with a vector fallback if the asset can't load.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.asset, required this.width});

  /// The asset's native proportions (354x264).
  static const double aspectRatio = 354 / 264;

  final String asset;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Center(
        child: SizedBox(
          width: width,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.softMint.withValues(alpha: 0.5),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.volunteer_activism,
                    size: 72,
                    color: AppColors.deepGreen,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width pill "Get started" button.
class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.deepGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(54),
        shape: const StadiumBorder(),
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label),
    );
  }
}
