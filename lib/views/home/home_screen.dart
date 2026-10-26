import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../profile/profile_screen.dart';
import 'home_feed.dart';
import 'requests_tab.dart';

/// View: main shell with a bottom navigation bar for Home, Give (opens the
/// create-post form), community Requests, and Profile.
///
/// Always uses the light brand theme so it matches the design even when the
/// device is in dark mode (same as the onboarding and login screens).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(data: AppTheme.lightTheme, child: const _HomeShell());
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  static const int _homeIndex = 0;
  static const int _giveIndex = 1;
  static const int _requestsIndex = 2;
  static const int _profileIndex = 3;

  int _navIndex = _homeIndex;

  void _onNavTap(int index) {
    // "Give" is an action, not a page: open the form and keep the tab.
    if (index == _giveIndex) {
      Navigator.of(context).pushNamed(AppRoutes.createGiveAway);
      return;
    }
    setState(() => _navIndex = index);
  }

  Widget _buildBody() {
    switch (_navIndex) {
      case _requestsIndex:
        return const _RequestsPage();
      case _profileIndex:
        return const ProfileScreen();
      default:
        return HomeFeed(onOpenProfile: () => _onNavTap(_profileIndex));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppColors.white,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppColors.softMint,
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? AppColors.deepGreen
                    : AppColors.textSecondary,
              ),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => textTheme.labelMedium?.copyWith(
                color: states.contains(WidgetState.selected)
                    ? AppColors.deepGreen
                    : AppColors.textSecondary,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _navIndex,
            onDestinationSelected: _onNavTap,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                label: l10n.home,
              ),
              NavigationDestination(
                icon: const Icon(Icons.card_giftcard_outlined),
                label: l10n.homeGive,
              ),
              NavigationDestination(
                icon: const Icon(Icons.format_list_bulleted),
                label: l10n.requests,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                label: l10n.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// All open community requests, with a shortcut to post a new one.
class _RequestsPage extends StatelessWidget {
  const _RequestsPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.requests,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.deepGreen),
                    tooltip: l10n.homeRequestItemTitle,
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.createRequest),
                  ),
                ],
              ),
            ),
          ),
          const RequestsTab(),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
