import 'package:flutter/material.dart';

import '../../controllers/intro_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/app_theme.dart';

/// View: two swipeable intro pages shown after the splash, before the
/// welcome screen. Skip and the last page's button continue through
/// [IntroController].
///
/// Always uses the light brand theme, like the other pre-login screens.
class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(data: AppTheme.lightTheme, child: const _IntroBody());
  }
}

class _IntroPageData {
  const _IntroPageData({
    required this.asset,
    required this.title,
    required this.body,
  });

  final String asset;
  final String title;
  final String body;
}

class _IntroBody extends StatefulWidget {
  const _IntroBody();

  @override
  State<_IntroBody> createState() => _IntroBodyState();
}

class _IntroBodyState extends State<_IntroBody> {
  static const Duration _pageDuration = Duration(milliseconds: 350);

  final _controller = const IntroController();
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_IntroPageData> _pages(AppLocalizations l10n) => [
    _IntroPageData(
      asset: 'assets/images/onboarding_give.jpg',
      title: l10n.introGiveTitle,
      body: l10n.introGiveBody,
    ),
    _IntroPageData(
      asset: 'assets/images/onboarding_share.jpg',
      title: l10n.introShareTitle,
      body: l10n.introShareBody,
    ),
  ];

  void _finish() => _controller.finish(Navigator.of(context));

  void _next(int pageCount) {
    if (_page >= pageCount - 1) {
      _finish();
    } else if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(_page + 1);
    } else {
      _pageController.nextPage(
        duration: _pageDuration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _pages(l10n);
    final isLast = _page == pages.length - 1;
    final labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );

    return Scaffold(
      backgroundColor: AppColors.introBackground,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 8, top: 4),
                // Kept in the layout on the last page so nothing shifts.
                child: Visibility(
                  visible: !isLast,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      textStyle: labelStyle,
                    ),
                    child: Text(l10n.introSkip),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) => _IntroPage(
                  data: pages[index],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _PageDots(
              count: pages.length,
              current: _page,
              label: l10n.introPageLabel(_page + 1, pages.length),
            ),
            const SizedBox(height: 24),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ElevatedButton(
                    onPressed: () => _next(pages.length),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepGreen,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(54),
                      shape: const StadiumBorder(),
                      textStyle: labelStyle,
                    ),
                    child: Text(l10n.introNext),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// One page: illustration that shrinks to fit, then title and description.
class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.data});

  final _IntroPageData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: _FadedEdges(
                    child: Image.asset(data.asset, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data.body,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fades the outer edges of [child] to transparent, so the illustration's
/// slightly lighter background doesn't show as a box against the page.
class _FadedEdges extends StatelessWidget {
  const _FadedEdges({required this.child});

  final Widget child;

  static Widget _fade(Widget child, Alignment begin, Alignment end) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: begin,
        end: end,
        // Only the alpha matters: it's a mask, not a visible color.
        colors: const [
          Colors.transparent,
          Colors.black,
          Colors.black,
          Colors.transparent,
        ],
        stops: const [0, 0.1, 0.9, 1],
      ).createShader(bounds),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // FittedBox makes the mask hug the painted image rather than the
    // whole Expanded area, so the fade lands on the image's own edges.
    return FittedBox(
      child: _fade(
        _fade(child, Alignment.centerLeft, Alignment.centerRight),
        Alignment.topCenter,
        Alignment.bottomCenter,
      ),
    );
  }
}

/// Row of dots; the current page's dot is a wider green pill.
class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.current,
    required this.label,
  });

  final int count;
  final int current;
  final String label;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: duration,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == current ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == current ? AppColors.deepGreen : AppColors.softMint,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
