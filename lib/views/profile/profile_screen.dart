import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/badge_controller.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/badge_model.dart';
import '../../models/user_model.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/user_avatar.dart';

/// View: the Profile tab — identity card, giving stats, badge progress,
/// the user's activity (donations, requests, reviews), settings, and
/// sign out. Shown inside the home shell, so it has no Scaffold of its own.
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
      backgroundColor: AppColors.white,
      builder: (sheetContext) => Theme(
        data: AppTheme.lightTheme,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  l10n.language,
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              for (final MapEntry(key: code, value: name)
                  in AppConstants.languageNames.entries)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  title: Text(
                    name,
                    style: TextStyle(
                      color:
                          code == selected ? AppColors.deepGreen : AppColors.ink,
                      fontWeight:
                          code == selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  trailing: code == selected
                      ? const Icon(Icons.check, color: AppColors.deepGreen)
                      : null,
                  onTap: () {
                    languageController.setLanguage(code);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Theme(
        data: AppTheme.lightTheme,
        child: AlertDialog(
          backgroundColor: AppColors.white,
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
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(l10n.profileSignOut),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<AuthController>().logout();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = context.watch<ProfileController>();
    final authUserId = context.watch<AuthController>().currentUser?.id;
    final languageCode = context.watch<LanguageController>().locale.languageCode;
    final user = profile.user;

    // Also covers a profile still cached from a previous account.
    if (user == null || user.id != authUserId) {
      return const LoadingIndicator();
    }

    final badgeController = context.read<BadgeController>();
    final badge = badgeController.badgeForDonationCount(user.donationCount);
    final nextBadge = badgeController.nextBadge(user.donationCount);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _Header(
              title: l10n.profileTitle,
              editTooltip: l10n.profileEditProfile,
              onEdit: _openEditProfile,
            ),
            const SizedBox(height: 16),
            _IdentityCard(
              user: user,
              badgeLabel: badge == null
                  ? l10n.homeNewDonor
                  : '${badge.level} · ${badge.name}',
              badgeColor: badge == null
                  ? AppColors.softMint
                  : _tierColor(badge.name),
              editLabel: l10n.profileEditProfile,
              onEdit: _openEditProfile,
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _StatTile(
                      value: '${user.donationCount}',
                      label: l10n.profileItemsGiven,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      value: '${profile.myRequests.length}',
                      label: l10n.requests,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      value: user.ratingCount == 0
                          ? '–'
                          : user.averageRating.toStringAsFixed(1),
                      label: l10n.profileRating,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _BadgeProgressCard(
              donationCount: user.donationCount,
              nextBadge: nextBadge,
            ),
            const SizedBox(height: 12),
            _MenuSection(
              title: l10n.profileMyActivity,
              tiles: [
                _MenuTile(
                  icon: const Icon(Icons.card_giftcard_outlined),
                  label: l10n.profileMyDonations,
                  trailing: '${profile.myPosts.length}',
                  onTap: () => _openRoute(AppRoutes.myDonations),
                ),
                _MenuTile(
                  icon: const Icon(Icons.format_list_bulleted),
                  label: l10n.myRequests,
                  trailing: '${profile.myRequests.length}',
                  onTap: () => _openRoute(AppRoutes.myRequests),
                ),
                _MenuTile(
                  icon: const Icon(Icons.star_border),
                  label: l10n.profileReviews,
                  trailing: '${profile.myReviews.length}',
                  onTap: () => _openRoute(AppRoutes.myReviews),
                ),
              ],
            ),
            if (user.isAdmin) ...[
              const SizedBox(height: 12),
              _MenuSection(
                title: l10n.profileAdmin,
                tiles: [
                  _MenuTile(
                    icon: const Icon(Icons.people_outline),
                    label: l10n.profileManageUsers,
                    onTap: () => _openRoute(AppRoutes.adminUsers),
                  ),
                  _MenuTile(
                    icon: const Icon(Icons.flag_outlined),
                    label: l10n.profileModeratePosts,
                    onTap: () => _openRoute(AppRoutes.adminPosts),
                  ),
                  _MenuTile(
                    icon: const Icon(Icons.category_outlined),
                    label: l10n.profileManageCategories,
                    onTap: () => _openRoute(AppRoutes.adminCategories),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _MenuSection(
              title: l10n.settings,
              tiles: [
                _MenuTile(
                  icon: const AppIcon(AppGlyph.language),
                  label: l10n.language,
                  trailing: AppConstants.languageNames[languageCode],
                  onTap: () => _showLanguagePicker(l10n),
                ),
                _MenuTile(
                  icon: const AppIcon(AppGlyph.notifications),
                  label: l10n.profileNotifications,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.profileNotificationsUnavailable),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _confirmSignOut(l10n),
              icon: const Icon(Icons.logout, size: 20),
              label: Text(l10n.profileSignOut),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                backgroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size.fromHeight(54),
                shape: const StadiumBorder(),
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brand color for each badge tier.
Color _tierColor(String badgeName) => switch (badgeName) {
      'Bronze' => AppColors.bronze,
      'Silver' => AppColors.silver,
      'Gold' => AppColors.amber,
      _ => AppColors.textSecondary,
    };

/// White rounded card with a soft shadow; clips ink ripples to its shape.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.editTooltip,
    required this.onEdit,
  });

  final String title;
  final String editTooltip;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: AppColors.white,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.border),
          ),
          child: IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.ink),
            tooltip: editTooltip,
            onPressed: onEdit,
          ),
        ),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.user,
    required this.badgeLabel,
    required this.badgeColor,
    required this.editLabel,
    required this.onEdit,
  });

  final UserModel user;
  final String badgeLabel;
  final Color badgeColor;
  final String editLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final location = [user.city, user.district]
        .where((part) => part.trim().isNotEmpty)
        .join(', ');
    return _SectionCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          UserAvatar(url: user.avatarUrl),
          const SizedBox(height: 14),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    location,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    badgeLabel,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.deepGreen,
              side: const BorderSide(color: AppColors.deepGreen),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              textStyle: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(editLabel),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.deepGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress toward the next badge plus a legend of every tier.
class _BadgeProgressCard extends StatelessWidget {
  const _BadgeProgressCard({
    required this.donationCount,
    required this.nextBadge,
  });

  final int donationCount;

  /// Null once every badge has been earned.
  final BadgeModel? nextBadge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final next = nextBadge;
    final tiers = AppConstants.badgeThresholds.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return _SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (next == null)
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined, color: AppColors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.profileAllBadgesEarned,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.profileNextBadge(next.name),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.profileBadgeProgress(
                    donationCount,
                    next.requiredDonations,
                  ),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: donationCount / next.requiredDonations,
                minHeight: 8,
                color: AppColors.brightGreen,
                backgroundColor: AppColors.mutedSurface,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final MapEntry(key: name, value: threshold) in tiers)
                _TierLegend(
                  name: name,
                  earned: donationCount >= threshold,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierLegend extends StatelessWidget {
  const _TierLegend({required this.name, required this.earned});

  final String name;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(name);
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
        const SizedBox(width: 6),
        Text(
          name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: earned ? AppColors.ink : AppColors.textSecondary,
                fontWeight: earned ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.tiles});

  final String title;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.border,
              ),
            tiles[i],
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  /// An [Icon] or [AppIcon]; sized and coloured by the tile.
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            IconTheme(
              data: const IconThemeData(size: 22, color: AppColors.deepGreen),
              child: icon,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              // Capped rather than Flexible, so the label keeps all the
              // spare width and the value + arrow sit at the row's end.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  trailing!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 6),
            const RowChevron(),
          ],
        ),
      ),
    );
  }
}
