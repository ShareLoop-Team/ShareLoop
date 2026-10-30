import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/profile_controller.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../models/exchange_model.dart';
import '../../models/item_post_model.dart';
import '../../models/item_request_model.dart';
import '../../widgets/illustrated_empty_state.dart';
import 'activity_page.dart';

/// Exchange history from the existing two-party handover workflow.
class MyExchangesScreen extends StatelessWidget {
  const MyExchangesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = context.watch<ProfileController>();
    final userId = profile.user?.id;
    final exchanges = profile.myExchanges;
    return ActivityPage(
      title: l10n.profileMyExchanges,
      subtitle: l10n.myExchangesSubtitle,
      isEmpty: exchanges.isEmpty,
      emptyState: IllustratedEmptyState(
        illustration: 'assets/images/empty_donations.svg',
        title: l10n.myExchangesEmptyTitle,
        message: l10n.myExchangesEmptyBody,
      ),
      items: [
        for (final exchange in exchanges)
          _ExchangeCard(
            exchange: exchange,
            post: exchange.itemPostId == null
                ? null
                : profile.exchangePosts[exchange.itemPostId],
            request: exchange.requestId == null
                ? null
                : profile.exchangeRequests[exchange.requestId],
            userId: userId ?? '',
          ),
      ],
      action: null,
    );
  }
}

class _ExchangeCard extends StatelessWidget {
  const _ExchangeCard({
    required this.exchange,
    required this.post,
    required this.request,
    required this.userId,
  });

  final ExchangeModel exchange;
  final ItemPostModel? post;
  final ItemRequestModel? request;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDonor = exchange.donorId == userId;
    final title =
        post?.title ??
        (request?.itemName.isNotEmpty == true
            ? request!.itemName
            : l10n.myExchangesUnknownItem);
    final donorName = post?.donorName ?? l10n.myExchangesDonor;
    final requesterName = request?.requesterName ?? l10n.myExchangesRequester;
    final status = switch (exchange.status) {
      ExchangeStatus.pending => l10n.myExchangesPending,
      ExchangeStatus.completed => l10n.myExchangesCompleted,
      ExchangeStatus.cancelled => l10n.myExchangesCancelled,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                const SizedBox(width: 8),
                Chip(label: Text(status)),
              ],
            ),
            if (post != null) ...[
              const SizedBox(height: 4),
              Text(
                '${post!.category} · ${post!.city}, ${post!.district}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              isDonor
                  ? l10n.myExchangesYouAnd(requesterName)
                  : l10n.myExchangesWith(donorName),
            ),
            const SizedBox(height: 8),
            _ConfirmationLine(
              label: l10n.myExchangesDonorConfirmation,
              confirmed: exchange.donorConfirmedAt != null,
              confirmedAt: exchange.donorConfirmedAt,
            ),
            _ConfirmationLine(
              label: l10n.myExchangesRequesterConfirmation,
              confirmed: exchange.requesterConfirmedAt != null,
              confirmedAt: exchange.requesterConfirmedAt,
            ),
            if (exchange.isCompleted) ...[
              const SizedBox(height: 8),
              Text(
                l10n.myExchangesBothConfirmed,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfirmationLine extends StatelessWidget {
  const _ConfirmationLine({
    required this.label,
    required this.confirmed,
    required this.confirmedAt,
  });

  final String label;
  final bool confirmed;
  final DateTime? confirmedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            confirmed ? Icons.check_circle_outline : Icons.schedule_outlined,
            size: 18,
            color: confirmed
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              confirmedAt == null
                  ? label
                  : '$label · ${MaterialLocalizations.of(context).formatShortDate(confirmedAt!)}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
