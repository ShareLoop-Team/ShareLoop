import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/profile_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/time_ago.dart';
import '../../models/item_request_model.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/illustrated_empty_state.dart';
import '../../widgets/info_note.dart';
import '../../widgets/status_chip.dart';
import 'activity_page.dart';

/// View: the items the signed-in user has asked for, newest first.
class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requests = context.watch<ProfileController>().myRequests;
    final navigator = Navigator.of(context);

    return ActivityPage(
      title: l10n.myRequests,
      subtitle: l10n.myRequestsSubtitle,
      isEmpty: requests.isEmpty,
      emptyState: IllustratedEmptyState(
        illustration: 'assets/images/empty_requests.svg',
        title: l10n.myRequestsEmptyTitle,
        message: l10n.myRequestsEmptyBody,
        footer: _Tip(label: l10n.myRequestsTipLabel, text: l10n.myRequestsTip),
      ),
      items: [
        for (final request in requests)
          _RequestCard(
            request: request,
            onTap: request.itemPostId == null
                ? null
                : () => navigator.pushNamed(
                      AppRoutes.itemDetails,
                      arguments: request.itemPostId,
                    ),
          ),
      ],
      action: ActivityAction(
        label: l10n.myRequestsAction,
        icon: Icons.add,
        onOpen: () => navigator.pushNamed(AppRoutes.createRequest),
      ),
    );
  }
}

/// "Tip: …" in a mint box with a star.
class _Tip extends StatelessWidget {
  const _Tip({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return InfoNote(icon: Icons.star_border, boldPrefix: label, text: text);
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});

  final ItemRequestModel request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final title =
        request.itemName.isEmpty ? request.description : request.itemName;
    return SoftCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip.forRequest(l10n, request.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${request.category} · ${request.district}',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (request.reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '"${request.reason}"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                timeAgo(l10n, request.createdAt),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (onTap != null) ...[
                const Spacer(),
                const RowChevron(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
