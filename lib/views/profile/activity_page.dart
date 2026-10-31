import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/theme/sl_tokens.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/subpage_header.dart';

/// Shared frame for the profile's My Requests / My Donations / Reviews
/// pages: header, pull-to-refresh, an empty state centred in the free space
/// or the list, and the main action pinned at the bottom.
class ActivityPage extends StatelessWidget {
  const ActivityPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isEmpty,
    required this.emptyState,
    required this.items,
    required this.action,
  });

  final String title;
  final String subtitle;
  final bool isEmpty;
  final Widget emptyState;

  /// List content shown when not [isEmpty].
  final List<Widget> items;
  final Widget? action;

  /// Reloads the signed-in user's posts, requests and reviews.
  static Future<void> refresh(BuildContext context) async {
    final userId = context.read<AuthController>().currentUser?.id;
    if (userId != null) {
      await context.read<ProfileController>().loadProfile(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    return Scaffold(
      backgroundColor: sl.ground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: SubpageHeader(title: title, subtitle: subtitle),
            ),
            Expanded(
              child: RefreshIndicator(
                color: sl.accentText,
                onRefresh: () => refresh(context),
                child: LayoutBuilder(
                  builder: (context, constraints) => isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 24,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 48,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 480,
                                ),
                                child: emptyState,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          itemCount: items.length,
                          itemBuilder: (_, index) => Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: items[index],
                            ),
                          ),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: action == null
          ? null
          : BottomActionBar(children: [action!]),
    );
  }
}

/// Main action button of an activity page; refreshes the lists when the
/// opened screen (e.g. a new post) closes.
class ActivityAction extends StatelessWidget {
  const ActivityAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onOpen,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final Future<void> Function() onOpen;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return PillButton(
      label: label,
      icon: icon,
      outlined: outlined,
      onPressed: () async {
        await onOpen();
        if (context.mounted) await ActivityPage.refresh(context);
      },
    );
  }
}
