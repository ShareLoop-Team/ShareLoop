import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/localization/generated/app_localizations.dart';
import '../models/item_post_model.dart';
import '../models/item_request_model.dart';

/// Small tinted pill showing a post's or request's status.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  factory StatusChip.forPost(AppLocalizations l10n, ItemPostStatus status) =>
      switch (status) {
        ItemPostStatus.active =>
          StatusChip(label: l10n.statusAvailable, color: AppColors.deepGreen),
        ItemPostStatus.pendingHandover =>
          StatusChip(label: l10n.statusHandoverPending, color: AppColors.amber),
        ItemPostStatus.completed =>
          StatusChip(label: l10n.statusGiven, color: AppColors.textSecondary),
      };

  factory StatusChip.forRequest(
    AppLocalizations l10n,
    ItemRequestStatus status,
  ) =>
      switch (status) {
        ItemRequestStatus.pending =>
          StatusChip(label: l10n.statusPending, color: AppColors.amber),
        ItemRequestStatus.approved =>
          StatusChip(label: l10n.statusApproved, color: AppColors.deepGreen),
        ItemRequestStatus.rejected => StatusChip(
            label: l10n.statusNotSelected,
            color: AppColors.textSecondary,
          ),
      };

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
