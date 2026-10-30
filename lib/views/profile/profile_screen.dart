import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/badge_controller.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/data_labels.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/sl_tokens.dart';
import '../../models/badge_model.dart';
import '../../models/user_model.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/donor_badge_dot.dart';
import '../../widgets/notification_prompt.dart';
import '../../widgets/sl/sl_button.dart';
import '../../widgets/sl/sl_motion.dart';
import '../../widgets/sl/sl_panel.dart';
import '../../widgets/sl/sl_states.dart';
import '../../widgets/user_avatar.dart';

/// View: the Profile tab — who you are, your giving stats and badge
/// progress, your activity (donations, requests, reviews), settings, and
/// sign out. Flat panels on the page tone, no decoration. Shown inside the
/// home shell, so it has no Scaffold of its own.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AuthController>().currentUser?.id;
    if (userId != null) {
      await context.read<ProfileController>().loadProfile(userId);
    }
  }

  void _openEditProfile() =>
      Navigator.of(context).pushNamed(AppRoutes.editProfile);

  void _openRoute(String route) => Navigator.of(context).pushNamed(route);

  void _showLanguagePicker(AppLocalizations l10n) {
    final languageController = context.read<LanguageController>();
    final selected = languageController.locale.languageCode;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final sl = sheetContext.sl;
        final type = sheetContext.slType;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SLSpace.screen,
                  0,
                  SLSpace.screen,
                  SLSpace.s,
                ),
                child: Text(l10n.language, style: type.section),
              ),
              for (final MapEntry(key: code, value: name)
                  in AppConstants.languageNames.entries)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: SLSpace.screen,
                  ),
                  title: Text(
                    name,
                    style: type.body.copyWith(
                      color: code == selected ? sl.accentText : sl.ink,
                      fontWeight: code == selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  trailing: code == selected
                      ? Icon(Icons.check, color: sl.accentText)
                      : null,
                  onTap: () {
                    languageController.setLanguage(code);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const SizedBox(height: SLSpace.s),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmSignOut(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileSignOutConfirm),
        content: Text(l10n.profileSignOutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: dialogContext.sl.danger,
            ),
            child: Text(l10n.profileSignOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<AuthController>().logout();
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = context.watch<ProfileController>();
    final authUserId = context.watch<AuthController>().currentUser?.id;
    final languageCode = context
        .watch<LanguageController>()
        .locale
        .languageCode;
    final user = profile.user;

    // Also covers a profile still cached from a previous account.
    if (user == null || user.id != authUserId) {
      // A failed load would otherwise spin forever.
      if (profile.errorMessage case final error? when !profile.isLoading) {
        return SafeArea(
          child: Center(
            child: SLErrorState(
              message: error,
              retryLabel: l10n.stateRetry,
              onRetry: _load,
            ),
          ),
        );
      }
      return const _ProfileSkeleton();
    }

    final badgeController = context.read<BadgeController>();
    final badge = badgeController.badgeForDonationCount(user.donationCount);
    final nextBadge = badgeController.nextBadge(user.donationCount);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            SLSpace.screen,
            SLSpace.m,
            SLSpace.screen,
            SLSpace.xl,
          ),
          children: [
            _TitleRow(
              title: l10n.profileTitle,
              notificationsTooltip: l10n.profileNotifications,
              onNotifications: () => manageNotifications(context),
            ),
            const SizedBox(height: SLSpace.l),
            _IdentityPanel(
              user: user,
              badgeName: badge?.name,
              badgeLabel: badge == null
                  ? l10n.homeNewDonor
                  : '${l10n.badgeLevel(badge.level)} · '
                        '${l10n.badge(badge.name)}',
              editLabel: l10n.profileEditProfile,
              onEdit: _openEditProfile,
            ),
            const SizedBox(height: SLSpace.m),
            _StatsPanel(
              stats: [
                ('${user.donationCount}', l10n.profileItemsGiven),
                ('${profile.myRequests.length}', l10n.requests),
                (
                  user.ratingCount == 0
                      ? '–'
                      : user.averageRating.toStringAsFixed(1),
                  l10n.profileRating,
                ),
              ],
            ),
            const SizedBox(height: SLSpace.m),
            _BadgeProgressPanel(
              donationCount: user.donationCount,
              nextBadge: nextBadge,
            ),
            const SizedBox(height: SLSpace.section),
            _RowGroup(
              title: l10n.profileMyActivity,
              rows: [
                SLListRow(
                  icon: const Icon(Icons.card_giftcard_outlined),
                  label: l10n.profileMyDonations,
                  value: '${profile.myPosts.length}',
                  onTap: () => _openRoute(AppRoutes.myDonations),
                ),
                SLListRow(
                  icon: const Icon(Icons.format_list_bulleted),
                  label: l10n.myRequests,
                  value: '${profile.myRequests.length}',
                  onTap: () => _openRoute(AppRoutes.myRequests),
                ),
                SLListRow(
                  icon: const Icon(Icons.star_border),
                  label: l10n.profileReviews,
                  value: '${profile.myReviews.length}',
                  onTap: () => _openRoute(AppRoutes.myReviews),
                ),
                SLListRow(
                  icon: const Icon(Icons.handshake_outlined),
                  label: l10n.profileMyExchanges,
                  value: '${profile.myExchanges.length}',
                  onTap: () => _openRoute(AppRoutes.myExchanges),
                ),
              ],
            ),
            if (user.isAdmin) ...[
              const SizedBox(height: SLSpace.section),
              _RowGroup(
                title: l10n.profileAdmin,
                rows: [
                  SLListRow(
                    icon: const Icon(Icons.people_outline),
                    label: l10n.profileManageUsers,
                    onTap: () => _openRoute(AppRoutes.adminUsers),
                  ),
                  SLListRow(
                    icon: const Icon(Icons.flag_outlined),
                    label: l10n.profileModeratePosts,
                    onTap: () => _openRoute(AppRoutes.adminPosts),
                  ),
                  SLListRow(
                    icon: const Icon(Icons.category_outlined),
                    label: l10n.profileManageCategories,
                    onTap: () => _openRoute(AppRoutes.adminCategories),
                  ),
                ],
              ),
            ],
            const SizedBox(height: SLSpace.section),
            _RowGroup(
              title: l10n.settings,
              rows: [
                SLListRow(
                  icon: const AppIcon(AppGlyph.language),
                  label: l10n.language,
                  value: AppConstants.languageNames[languageCode],
                  onTap: () => _showLanguagePicker(l10n),
                ),
                SLListRow(
                  icon: const AppIcon(AppGlyph.notifications),
                  label: l10n.profileNotifications,
                  onTap: () => manageNotifications(context),
                ),
              ],
            ),
            const SizedBox(height: SLSpace.section),
            // Destructive, so last and on its own.
            SLPanel(
              children: [
                SLListRow(
                  icon: const Icon(Icons.logout),
                  label: l10n.profileSignOut,
                  destructive: true,
                  showChevron: false,
                  onTap: () => _confirmSignOut(l10n),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "My Profile" and the bell that opens notification settings.
class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.title,
    required this.notificationsTooltip,
    required this.onNotifications,
  });

  final String title;
  final String notificationsTooltip;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            // Two lines at most, for long Tamil titles on small phones.
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.slType.title,
            ),
          ),
        ),
        IconButton(
          tooltip: notificationsTooltip,
          onPressed: onNotifications,
          icon: IconTheme(
            data: IconThemeData(size: 24, color: context.sl.ink),
            child: const AppIcon(AppGlyph.notifications),
          ),
        ),
      ],
    );
  }
}

/// Photo, name, email, city and badge, with the way into Edit Profile.
class _IdentityPanel extends StatelessWidget {
  const _IdentityPanel({
    required this.user,
    required this.badgeName,
    required this.badgeLabel,
    required this.editLabel,
    required this.onEdit,
  });

  final UserModel user;

  /// Badge name for its colour, or null for new donors.
  final String? badgeName;
  final String badgeLabel;
  final String editLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    final type = context.slType;
    final location = [
      user.city,
      user.district,
    ].where((part) => part.trim().isNotEmpty).join(', ');
    return SLPanel(
      padding: const EdgeInsets.all(SLSpace.l),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                UserAvatar(url: user.avatarUrl, size: 64, ringWidth: 2),
                const SizedBox(width: SLSpace.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: type.section,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: type.small,
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: sl.inkMuted,
                            ),
                            const SizedBox(width: SLSpace.xs),
                            Flexible(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: type.small,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: SLSpace.m),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SLSpace.m,
                  vertical: SLSpace.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: sl.accentSoft,
                  borderRadius: BorderRadius.circular(SLRadius.control),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DonorBadgeDot(badge: badgeName),
                    const SizedBox(width: SLSpace.s - 2),
                    Flexible(
                      child: Text(
                        badgeLabel,
                        style: type.small.copyWith(
                          color: sl.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: SLSpace.l),
            SLButton(
              label: editLabel,
              icon: Icons.edit_outlined,
              variant: SLButtonVariant.secondary,
              expand: true,
              onPressed: onEdit,
            ),
          ],
        ),
      ],
    );
  }
}

/// The giving numbers in one panel, divided by thin lines.
class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.stats});

  /// (value, label) pairs.
  final List<(String, String)> stats;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    final type = context.slType;
    return SLPanel(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0)
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    indent: SLSpace.m,
                    endIndent: SLSpace.m,
                    color: sl.divider,
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SLSpace.s,
                      vertical: SLSpace.l,
                    ),
                    // Top-aligned, so the numbers line up even when a
                    // translated label wraps to more lines than its
                    // neighbours.
                    child: Column(
                      children: [
                        Text(
                          stats[i].$1,
                          style: type.section.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stats[i].$2,
                          textAlign: TextAlign.center,
                          style: type.small,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Progress toward the next badge plus a legend of every tier.
class _BadgeProgressPanel extends StatelessWidget {
  const _BadgeProgressPanel({
    required this.donationCount,
    required this.nextBadge,
  });

  final int donationCount;

  /// Null once every badge has been earned.
  final BadgeModel? nextBadge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sl = context.sl;
    final type = context.slType;
    final next = nextBadge;
    final tiers = AppConstants.badgeThresholds.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return SLPanel(
      padding: const EdgeInsets.all(SLSpace.l),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (next == null)
              Row(
                children: [
                  Icon(Icons.emoji_events_outlined, color: sl.accentText),
                  const SizedBox(width: SLSpace.s),
                  Expanded(
                    child: Text(
                      l10n.profileAllBadgesEarned,
                      style: type.cardTitle,
                    ),
                  ),
                ],
              )
            else ...[
              LayoutBuilder(
                builder: (context, constraints) => Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.profileNextBadge(l10n.badge(next.name)),
                        style: type.cardTitle,
                      ),
                    ),
                    const SizedBox(width: SLSpace.s),
                    // At the row's end; long in Tamil, so it may wrap.
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.4,
                      ),
                      child: Text(
                        l10n.profileBadgeProgress(
                          donationCount,
                          next.requiredDonations,
                        ),
                        textAlign: TextAlign.end,
                        style: type.small,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SLSpace.m),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: donationCount / next.requiredDonations,
                  minHeight: 8,
                  color: sl.accent,
                  backgroundColor: sl.surfaceMuted,
                ),
              ),
            ],
            const SizedBox(height: SLSpace.m),
            Wrap(
              spacing: SLSpace.l,
              runSpacing: SLSpace.s,
              children: [
                for (final MapEntry(key: name, value: threshold) in tiers)
                  _TierLegend(
                    label: l10n.badge(name),
                    color: DonorBadgeDot.colorFor(name),
                    earned: donationCount >= threshold,
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _TierLegend extends StatelessWidget {
  const _TierLegend({
    required this.label,
    required this.color,
    required this.earned,
  });

  final String label;
  final Color color;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: earned ? color : null,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: SLSpace.s - 2),
        Text(
          label,
          style: context.slType.small.copyWith(
            color: earned ? sl.ink : sl.inkMuted,
            fontWeight: earned ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/// A section title over one panel of rows.
class _RowGroup extends StatelessWidget {
  const _RowGroup({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SLSectionHeader(title: title),
        const SizedBox(height: SLSpace.s),
        SLPanel(dividerIndent: SLListRow.labelInset, children: rows),
      ],
    );
  }
}

/// The profile's layout in flat grey blocks while it loads.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SLSpace.screen,
          SLSpace.l,
          SLSpace.screen,
          0,
        ),
        child: SLLoadingPulse(child: _blocks()),
      ),
    );
  }

  Widget _blocks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SLSkeleton(width: 160, height: 28),
        const SizedBox(height: SLSpace.l),
        SLPanel(
          padding: const EdgeInsets.all(SLSpace.l),
          children: [
            Row(
              children: [
                const SLSkeleton(width: 64, height: 64, radius: 32),
                const SizedBox(width: SLSpace.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SLSkeleton(width: 140, height: 18),
                      SizedBox(height: SLSpace.s),
                      SLSkeleton(width: 180),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: SLSpace.m),
        const SLSkeleton(height: 84, radius: SLRadius.card),
      ],
    );
  }
}
