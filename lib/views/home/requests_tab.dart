import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/request_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/sl_tokens.dart';
import '../../core/utils/time_ago.dart';
import '../../models/item_request_model.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/user_avatar.dart';
import '../requests/create_request_screen.dart';

/// View: item requests as cards, newest first. Shows standalone community
/// requests narrowed by category/district/search, or with [onlyMine] the
/// signed-in user's own requests (including ones for specific posts).
/// Built as a sliver for scrolling pages.
class RequestsTab extends StatelessWidget {
  const RequestsTab({
    super.key,
    this.category,
    this.district,
    this.query = '',
    this.onlyMine = false,
    this.onClearFilters,
  });

  final String? category;
  final String? district;
  final String query;
  final bool onlyMine;

  /// Offered when the filters leave nothing to show.
  final VoidCallback? onClearFilters;

  bool get _filtered =>
      category != null || district != null || query.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final requestController = context.watch<RequestController>();
    final userId = context.watch<AuthController>().currentUser?.id;
    final l10n = AppLocalizations.of(context);

    if (requestController.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: LoadingIndicator(),
      );
    }
    final requests =
        (onlyMine
              ? requestController
                    .requestsByUser(userId ?? '')
                    .where((r) => category == null || r.category == category)
                    .toList()
              : requestController.communityRequests(
                  category: category,
                  district: district,
                  query: query,
                ))
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (requests.isEmpty) {
      final EmptyState state;
      if (requestController.errorMessage case final error?) {
        // A failed load is not "no requests": say so and offer a retry.
        state = EmptyState(
          icon: Icons.cloud_off_outlined,
          message: error,
          actionLabel: l10n.stateRetry,
          onAction: requestController.loadRequests,
        );
      } else if (_filtered && onClearFilters != null) {
        state = EmptyState(
          icon: Icons.search_off,
          message: l10n.stateNoMatches,
          actionLabel: l10n.stateClearFilters,
          onAction: onClearFilters,
        );
      } else {
        state = EmptyState(
          message: onlyMine ? l10n.profileNoRequests : l10n.noOpenRequests,
        );
      }
      return SliverFillRemaining(hasScrollBody: false, child: state);
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.separated(
        itemCount: requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _RequestCard(
          request: requests[index],
          isMine: requests[index].requesterId == userId,
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.isMine});

  final ItemRequestModel request;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final sl = context.sl;
    final isStandalone = request.itemPostId == null;
    final canHelp =
        isStandalone && !isMine && request.status == ItemRequestStatus.pending;
    // Once a donor has chosen this request, the handover depends on it.
    final canDelete = isMine && request.status != ItemRequestStatus.approved;
    final canEdit =
        isMine && context.read<RequestController>().canEdit(request);
    // Your own requests follow your current name and photo.
    final me = isMine ? context.watch<AuthController>().currentUser : null;
    final name = me?.name ?? request.requesterName;
    final avatarUrl = me != null ? me.avatarUrl : request.requesterAvatarUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sl.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  request.itemName.isEmpty
                      ? request.description
                      : request.itemName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: sl.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(request: request),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            request.reason,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(color: sl.inkMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(
                label: request.category,
                background: sl.accentSoft,
                foreground: sl.accentText,
              ),
              _Tag(
                label: request.district,
                icon: Icons.location_on_outlined,
                background: sl.surfaceMuted,
                foreground: sl.inkMuted,
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: sl.divider),
          ),
          Row(
            children: [
              if (avatarUrl case final url? when url.isNotEmpty)
                UserAvatar(url: url, size: 36, ringWidth: 1.5)
              else
                CircleAvatar(
                  radius: 18,
                  backgroundColor: sl.accentSoft,
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: sl.accentText,
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: sl.ink,
                      ),
                    ),
                    Text(
                      '${request.city} · ${timeAgo(l10n, request.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: sl.inkMuted),
                    ),
                  ],
                ),
              ),
              if (canHelp) ...[
                const SizedBox(width: 8),
                // Long translations shrink the button rather than overflow.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: OutlinedButton(
                    // Opens the Give form pre-filled with what they need.
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.createGiveAway, arguments: request),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: sl.accentText,
                      side: BorderSide(color: sl.accentText),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      textStyle: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(
                      l10n.requestsICanHelp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ] else ...[
                if (canEdit)
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            CreateRequestScreen(editRequest: request),
                      ),
                    ),
                    tooltip: l10n.requestsEdit,
                    icon: const Icon(Icons.edit_outlined),
                    color: sl.accentText,
                  ),
                if (canDelete)
                  IconButton(
                    onPressed: () => _confirmDelete(context),
                    tooltip: l10n.requestsDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: sl.danger,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = context.read<RequestController>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.requestsDeleteConfirm,
      message: l10n.requestsDeleteMessage,
      actionLabel: l10n.requestsDeleteAction,
    );
    if (!confirmed) return;
    final error = await controller.deleteRequest(request.id);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? l10n.requestsDeleted)),
    );
  }
}

/// Where the request stands: open to any donor, being reviewed by the
/// donor of a specific post, or decided.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.request});

  final ItemRequestModel request;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sl = context.sl;
    final (label, icon, color) = switch (request.status) {
      ItemRequestStatus.pending when request.itemPostId == null => (
        l10n.statusOpen,
        Icons.radio_button_unchecked,
        sl.accentText,
      ),
      ItemRequestStatus.pending => (
        l10n.statusDonorReviewing,
        Icons.schedule,
        AppColors.amber,
      ),
      ItemRequestStatus.approved => (
        l10n.statusApproved,
        Icons.check_circle_outline,
        sl.accentText,
      ),
      ItemRequestStatus.rejected => (
        l10n.statusNotSelected,
        Icons.remove_circle_outline,
        sl.inkMuted,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              // Amber text is too faint on its own tint.
              color: color == AppColors.amber ? sl.ink : color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
