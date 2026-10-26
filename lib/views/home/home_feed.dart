import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/item_controller.dart';
import '../../controllers/request_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_routes.dart';
import 'give_away_tab.dart';
import 'requests_tab.dart';

/// View: the Home tab — greeting, search, Give/Request shortcuts, a Give
/// Away / Requests switch, category chips, and the matching items near you.
/// Filters live in [ItemController] so the grid and request list share them.
class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key, required this.onOpenProfile});

  final VoidCallback onOpenProfile;

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  late final TextEditingController _searchController;
  bool _showRequests = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<ItemController>().searchQuery,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() => Future.wait([
        context.read<ItemController>().loadPosts(),
        context.read<RequestController>().loadRequests(),
      ]);

  void _showDistrictPicker(AppLocalizations l10n) {
    final itemController = context.read<ItemController>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (sheetContext) {
        void select(String? district) {
          itemController.setDistrictFilter(district);
          Navigator.of(sheetContext).pop();
        }

        final selected = itemController.districtFilter;
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  l10n.homeChooseDistrict,
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _DistrictTile(
                      label: l10n.homeAllDistricts,
                      selected: selected == null,
                      onTap: () => select(null),
                    ),
                    for (final district in AppConstants.sriLankanDistricts)
                      _DistrictTile(
                        label: district,
                        selected: selected == district,
                        onTap: () => select(district),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final itemController = context.watch<ItemController>();
    final user = context.watch<AuthController>().currentUser;
    final firstName = user?.name.trim().split(' ').first ?? '';

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverList.list(
                children: [
                  _Header(
                    greeting: firstName.isEmpty
                        ? l10n.homeGreetingGuest
                        : l10n.homeGreeting(firstName),
                    onProfileTap: widget.onOpenProfile,
                  ),
                  const SizedBox(height: 16),
                  _SearchField(
                    controller: _searchController,
                    hint: l10n.homeSearchHint,
                    onChanged: itemController.setSearchQuery,
                  ),
                  const SizedBox(height: 20),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.card_giftcard_outlined,
                            title: l10n.homeGiveItemTitle,
                            subtitle: l10n.homeGiveItemSubtitle,
                            filled: true,
                            onTap: () => Navigator.of(context)
                                .pushNamed(AppRoutes.createGiveAway),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.add,
                            title: l10n.homeRequestItemTitle,
                            subtitle: l10n.homeRequestItemSubtitle,
                            filled: false,
                            onTap: () => Navigator.of(context)
                                .pushNamed(AppRoutes.createRequest),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SegmentedToggle(
                    labels: [l10n.giveAway, l10n.requests],
                    selectedIndex: _showRequests ? 1 : 0,
                    onChanged: (index) =>
                        setState(() => _showRequests = index == 1),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: _CategoryChips(
                allLabel: l10n.homeAllCategories,
                selected: itemController.categoryFilter,
                onSelected: itemController.setCategoryFilter,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _showRequests
                            ? l10n.homeOpenRequests
                            : l10n.homeAvailableNearYou,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _DistrictButton(
                      label: itemController.districtFilter ??
                          l10n.homeAllDistricts,
                      onTap: () => _showDistrictPicker(l10n),
                    ),
                  ],
                ),
              ),
            ),
            if (_showRequests)
              RequestsTab(
                category: itemController.categoryFilter,
                district: itemController.districtFilter,
                query: itemController.searchQuery,
              )
            else
              const GiveAwayTab(),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.greeting, required this.onProfileTap});

  final String greeting;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: 'ShareLoop',
                excludeSemantics: true,
                child: Row(
                  children: [
                    const Icon(
                      Icons.eco_outlined,
                      color: AppColors.deepGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          const TextSpan(
                            children: [
                              TextSpan(text: 'Share'),
                              TextSpan(
                                text: 'Loop',
                                style: TextStyle(color: AppColors.deepGreen),
                              ),
                            ],
                          ),
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                greeting,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: AppColors.white,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.softMint),
          ),
          child: IconButton(
            icon: const Icon(Icons.person_outline, color: AppColors.deepGreen),
            tooltip: AppLocalizations.of(context).profile,
            onPressed: onProfileTap,
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.deepGreen),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// Filled cards use the brand green; outlined ones the pale mint.
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground = filled ? AppColors.white : AppColors.ink;
    return Material(
      color: filled ? AppColors.deepGreen : AppColors.paleMint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: filled
            ? BorderSide.none
            : const BorderSide(color: AppColors.softMint),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: filled
                      ? AppColors.white.withValues(alpha: 0.18)
                      : AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: filled ? AppColors.white : AppColors.deepGreen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: filled
                      ? AppColors.white.withValues(alpha: 0.9)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.mutedSurface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selectedIndex,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: i == selectedIndex ? AppColors.white : null,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: i == selectedIndex
                          ? [
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labels[i],
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: i == selectedIndex
                            ? AppColors.deepGreen
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.allLabel,
    required this.selected,
    required this.onSelected,
  });

  final String allLabel;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final chips = <(String, String?)>[
      (allLabel, null),
      for (final category in AppConstants.itemCategories) (category, category),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final (label, value) in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Pill(
                label: label,
                selected: selected == value,
                onTap: () => onSelected(value),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.deepGreen : AppColors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.deepGreen : AppColors.softMint,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected ? AppColors.white : AppColors.ink,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DistrictButton extends StatelessWidget {
  const _DistrictButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.softMint)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.deepGreen,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.deepGreen,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DistrictTile extends StatelessWidget {
  const _DistrictTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.deepGreen : AppColors.ink,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: AppColors.deepGreen)
          : null,
      onTap: onTap,
    );
  }
}
