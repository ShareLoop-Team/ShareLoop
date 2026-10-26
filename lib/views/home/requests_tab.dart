import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/request_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/utils/time_ago.dart';
import '../../models/item_request_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';

/// View: standalone item requests from the community, optionally narrowed
/// by category/district/search. Built as a sliver for scrolling pages.
class RequestsTab extends StatelessWidget {
  const RequestsTab({
    super.key,
    this.category,
    this.district,
    this.query = '',
  });

  final String? category;
  final String? district;
  final String query;

  @override
  Widget build(BuildContext context) {
    final requestController = context.watch<RequestController>();
    final l10n = AppLocalizations.of(context);

    if (requestController.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: LoadingIndicator(),
      );
    }
    final requests = requestController.communityRequests(
      category: category,
      district: district,
      query: query,
    );
    if (requests.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(message: l10n.noOpenRequests),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.separated(
        itemCount: requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _RequestCard(request: requests[index]),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final ItemRequestModel request;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.description,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            request.reason,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${request.category} · ${request.district}',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.deepGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${l10n.homeRequestedBy(request.requesterName)} · '
            '${timeAgo(l10n, request.createdAt)}',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
