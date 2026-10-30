import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/request_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/notification_permission_service.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/notification_prompt.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/segmented_toggle.dart';
import '../give_away/create_give_away_screen.dart';
import '../profile/profile_screen.dart';
import 'home_feed.dart';
import 'requests_tab.dart';

/// View: main shell with a bottom navigation bar for Home, Give (the
/// create-post form), community Requests, and Profile. System back on any
/// tab other than Home returns to Home.
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _afterSignIn());
  }

  /// Right after sign-in (not a restored session), once Home is on screen,
  /// offer notifications unless this device already answered.
  Future<void> _afterSignIn() async {
    if (!mounted) return;
    final service = context.read<NotificationPermissionService?>();
    final justSignedIn = context.read<AuthController>().takeJustSignedIn();
    if (service == null || !justSignedIn) return;
    if (!await service.shouldPrompt() || !mounted) return;
    await showNotificationPrompt(context, service);
  }

  /// Whether the Give tab's form holds input that leaving would discard.
  final _giveHasInput = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _giveHasInput.dispose();
    super.dispose();
  }

  /// Switches tabs, first asking before throwing away a half-filled Give
  /// form (leaving the tab disposes it, so it starts fresh next time).
  Future<void> _onNavTap(int index) async {
    if (index == _navIndex) return;
    if (_navIndex == _giveIndex && _giveHasInput.value) {
      if (!await confirmDiscardChanges(context) || !mounted) return;
      _giveHasInput.value = false;
    }
    setState(() => _navIndex = index);
  }

  Widget _buildBody() {
    switch (_navIndex) {
      case _giveIndex:
        return CreateGiveAwayScreen(
          onClose: () => _onNavTap(_homeIndex),
          hasUnsavedInput: _giveHasInput,
        );
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
    return PopScope(
      canPop: _navIndex == _homeIndex,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onNavTap(_homeIndex);
      },
      child: _buildScaffold(l10n, textTheme),
    );
  }

  Widget _buildScaffold(AppLocalizations l10n, TextTheme textTheme) {
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
                icon: const AppIcon(AppGlyph.home),
                label: l10n.home,
              ),
              NavigationDestination(
                icon: const AppIcon(AppGlyph.give),
                label: l10n.homeGive,
              ),
              NavigationDestination(
                icon: const AppIcon(AppGlyph.requests),
                label: l10n.requests,
              ),
              NavigationDestination(
                icon: const AppIcon(AppGlyph.profile),
                label: l10n.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Community requests (or just the user's own), filterable by category,
/// with a shortcut to post a new one.
class _RequestsPage extends StatefulWidget {
  const _RequestsPage();

  @override
  State<_RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<_RequestsPage> {
  bool _showMine = false;
  String? _category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => context.read<RequestController>().loadRequests(),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              sliver: SliverList.list(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.requests,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.requestsSubtitle,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRoutes.createRequest),
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(l10n.requestsNew),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepGreen,
                          foregroundColor: AppColors.white,
                          elevation: 4,
                          shadowColor: AppColors.deepGreen.withValues(
                            alpha: 0.4,
                          ),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          textStyle: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedToggle(
                    labels: [l10n.requestsAll, l10n.requestsMine],
                    selectedIndex: _showMine ? 1 : 0,
                    onChanged: (index) =>
                        setState(() => _showMine = index == 1),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: CategoryChipsRow(
                allLabel: l10n.homeAllCategories,
                selected: _category,
                onSelected: (value) => setState(() => _category = value),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            RequestsTab(
              category: _category,
              onlyMine: _showMine,
              onClearFilters: () => setState(() => _category = null),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
