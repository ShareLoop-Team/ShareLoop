import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/item_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/request_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/sri_lanka_locations.dart';
import '../../core/localization/data_labels.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/sl_tokens.dart';
import '../../models/user_model.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/sl/sl_chip.dart';
import '../../widgets/sl/sl_panel.dart';
import '../../widgets/use_my_location.dart';
import '../../widgets/user_avatar.dart';
import 'give_away_tab.dart';

/// View: the Home tab — the wordmark and profile photo, search, one row of
/// category chips, and the matching Give Away items near you (filtered to
/// the user's city). Filters live in [ItemController].
class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key, required this.onOpenProfile});

  final VoidCallback onOpenProfile;

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  late final TextEditingController _searchController;

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

  /// Resets the search box as well as the controller's filters.
  void _clearFilters() {
    _searchController.clear();
    context.read<ItemController>().clearFilters();
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ItemController>().setSearchQuery('');
  }

  Future<void> _refresh() => Future.wait([
    context.read<ItemController>().loadPosts(),
    context.read<RequestController>().loadRequests(),
  ]);

  /// Lets the user pick their city (saved to their profile, so Home and
  /// Edit Profile agree), detect it, or see items from all areas for now.
  /// [district] opens straight on that district's cities, with [note].
  Future<void> _showCityPicker(
    AppLocalizations l10n,
    UserModel? user, {
    String? district,
    String? note,
  }) async {
    final itemController = context.read<ItemController>();
    final profileDistrict = SriLankaLocations.validDistrict(user?.district);
    final profileCity = SriLankaLocations.validCity(
      profileDistrict,
      user?.city,
    );

    final choice = await showModalBottomSheet<_CityChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CityPickerSheet(
        initialDistrict: district ?? profileDistrict,
        selectedCity: itemController.cityFilter,
        offerAllAreas: profileCity != null,
        note: note,
      ),
    );
    if (choice == null || !mounted) return;
    if (choice.useMyLocation) {
      await _useMyLocation(l10n, user);
      return;
    }
    final city = choice.city;
    if (city == null || user == null || city == profileCity) {
      itemController.setCityFilter(city);
      return;
    }
    await _saveCity(l10n, user, district: choice.district!, city: city);
  }

  /// Saves [city] to [user]'s profile and filters Home to it. Returns
  /// whether it was saved.
  Future<bool> _saveCity(
    AppLocalizations l10n,
    UserModel user, {
    required String district,
    required String city,
  }) async {
    final itemController = context.read<ItemController>();
    final profile = context.read<ProfileController>();
    final auth = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);
    final saved = await profile.updateLocation(
      user,
      district: district,
      city: city,
    );
    if (!mounted) return false;
    if (saved == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(profile.errorMessage ?? l10n.editProfileFailed)),
      );
      return false;
    }
    auth.updateCurrentUser(saved);
    itemController
      ..applyProfileCity(city)
      // Also when it was already the profile city but "All areas" was on.
      ..setCityFilter(city);
    return true;
  }

  /// Detects the district and city and saves them like a manual pick. With
  /// only a district, its cities are offered; on failure the message says
  /// why and the manual picker stays one tap away.
  Future<void> _useMyLocation(AppLocalizations l10n, UserModel? user) async {
    final messenger = ScaffoldMessenger.of(context);
    final match = await detectMyLocation(context);
    if (match == null || !mounted) return;
    final city = match.city;
    if (city == null) {
      await _showCityPicker(
        l10n,
        user,
        district: match.district,
        note: l10n.locationDistrictOnly(match.district),
      );
      return;
    }
    if (user == null) {
      context.read<ItemController>().setCityFilter(city);
      return;
    }
    final saved = await _saveCity(
      l10n,
      user,
      district: match.district,
      city: city,
    );
    if (!saved || !mounted) return;
    showAppSnackBar(messenger, l10n.locationDetected(city, match.district));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final itemController = context.watch<ItemController>();
    final user = context.watch<AuthController>().currentUser;

    // Never a district shown as if it were a city: only a listed city of
    // the user's district counts.
    final profileCity = user == null
        ? null
        : SriLankaLocations.validCity(user.district, user.city);
    final cityApplied = itemController.hasAppliedProfileCity(profileCity);
    if (!cityApplied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ItemController>().applyProfileCity(profileCity);
        }
      });
    }
    final String cityLabel;
    if (!cityApplied) {
      cityLabel = profileCity ?? l10n.homeSelectCity;
    } else {
      cityLabel =
          itemController.cityFilter ??
          (profileCity == null ? l10n.homeSelectCity : l10n.homeAllAreas);
    }
    final cityFiltered = cityApplied && itemController.cityFilter != null;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          // Scrolling the results puts the search keyboard away.
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                SLSpace.screen,
                SLSpace.m,
                SLSpace.screen,
                0,
              ),
              sliver: SliverList.list(
                children: [
                  _Header(
                    avatarUrl: user?.avatarUrl,
                    profileLabel: l10n.profile,
                    onProfileTap: widget.onOpenProfile,
                  ),
                  const SizedBox(height: SLSpace.l),
                  _SearchField(
                    controller: _searchController,
                    hint: l10n.homeSearchHint,
                    clearTooltip: l10n.searchClear,
                    onChanged: itemController.setSearchQuery,
                    onClear: _clearSearch,
                  ),
                  const SizedBox(height: SLSpace.s),
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
              padding: const EdgeInsets.fromLTRB(
                SLSpace.screen,
                SLSpace.m,
                SLSpace.screen,
                SLSpace.m,
              ),
              sliver: SliverToBoxAdapter(
                child: SLSectionHeader(
                  title: l10n.homeAvailableNearYou,
                  trailing: SLChip(
                    label: cityLabel,
                    icon: Icons.location_on_outlined,
                    selected: cityFiltered,
                    onTap: () => _showCityPicker(l10n, user),
                  ),
                ),
              ),
            ),
            GiveAwayTab(onClearFilters: _clearFilters),
            const SliverToBoxAdapter(child: SizedBox(height: SLSpace.xl)),
          ],
        ),
      ),
    );
  }
}

/// "All" plus one chip per category, in one sideways-scrolling row.
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
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: SLSpace.screen),
      child: Row(
        children: [
          SLChip(
            label: allLabel,
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final category in AppConstants.itemCategories) ...[
            const SizedBox(width: SLSpace.s),
            SLChip(
              label: l10n.category(category),
              selected: selected == category,
              onTap: () => onSelected(category),
            ),
          ],
        ],
      ),
    );
  }
}

/// The ShareLoop wordmark and the user's photo, which opens Profile.
class _Header extends StatelessWidget {
  const _Header({
    required this.avatarUrl,
    required this.profileLabel,
    required this.onProfileTap,
  });

  static const double _avatarSize = 44;

  /// The signed-in user's photo; a person icon is shown without one.
  final String? avatarUrl;
  final String profileLabel;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: 'ShareLoop',
            header: true,
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Share'),
                  TextSpan(
                    text: 'Loop',
                    style: TextStyle(color: sl.accentText),
                  ),
                ],
              ),
              maxLines: 1,
              style: context.slType.title.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Tooltip(
          message: profileLabel,
          child: Semantics(
            button: true,
            child: InkResponse(
              onTap: onProfileTap,
              radius: _avatarSize / 2 + 4,
              child: (avatarUrl?.isNotEmpty ?? false)
                  ? UserAvatar(url: avatarUrl, size: _avatarSize, ringWidth: 2)
                  : Container(
                      width: _avatarSize,
                      height: _avatarSize,
                      decoration: BoxDecoration(
                        color: sl.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 24,
                        color: sl.accentText,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Flat search field, one tone above the page; green edge when focused.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.clearTooltip,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final String clearTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    final type = context.slType;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(SLRadius.control),
      borderSide: BorderSide.none,
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      style: type.body,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: type.body.copyWith(color: sl.inkMuted),
        prefixIcon: Icon(Icons.search, color: sl.inkMuted),
        // The parent rebuilds on every search change, so this tracks the
        // text without its own listener.
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                tooltip: clearTooltip,
                icon: Icon(Icons.close, color: sl.inkMuted),
              ),
        filled: true,
        fillColor: sl.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: sl.accentText, width: 1.5),
        ),
      ),
    );
  }
}

/// What the city picker returns: a city with its district, a null [city]
/// for "all areas", or a request to detect the location.
class _CityChoice {
  const _CityChoice({this.district, this.city}) : useMyLocation = false;

  const _CityChoice.useMyLocation()
    : district = null,
      city = null,
      useMyLocation = true;

  final String? district;
  final String? city;
  final bool useMyLocation;
}

/// Bottom sheet listing the cities of one district, with a step back to
/// the district list (shown first when the user has no district yet).
class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet({
    required this.initialDistrict,
    required this.selectedCity,
    required this.offerAllAreas,
    this.note,
  });

  final String? initialDistrict;
  final String? selectedCity;

  /// Only once the user has a city is there a narrower view to leave.
  final bool offerAllAreas;

  /// Shown under the title, e.g. which district was detected.
  final String? note;

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  late String? _district = widget.initialDistrict;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sl = context.sl;
    final type = context.slType;
    final district = _district;
    final navigator = Navigator.of(context);

    return FractionallySizedBox(
      heightFactor: 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SLSpace.screen,
              0,
              SLSpace.screen,
              SLSpace.xs,
            ),
            child: Text(
              district == null ? l10n.homeChooseDistrict : l10n.homeChooseCity,
              style: type.section,
            ),
          ),
          if (widget.note case final note?)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SLSpace.screen,
                2,
                SLSpace.screen,
                SLSpace.xs,
              ),
              child: Text(
                note,
                style: type.small.copyWith(
                  color: sl.accentText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (district != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SLSpace.screen,
                0,
                SLSpace.s,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.homeCityDistrict(district),
                      style: type.small,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _district = null),
                    style: TextButton.styleFrom(
                      foregroundColor: sl.accentText,
                      textStyle: type.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(l10n.homeChangeDistrict),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              // Each district's cities start from the top.
              key: ValueKey(district),
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: SLSpace.screen,
                  ),
                  leading: Icon(
                    Icons.my_location_rounded,
                    color: sl.accentText,
                  ),
                  title: Text(
                    l10n.locationUseMine,
                    style: type.body.copyWith(
                      color: sl.accentText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => navigator.pop(const _CityChoice.useMyLocation()),
                ),
                Divider(
                  height: 1,
                  indent: SLSpace.screen,
                  endIndent: SLSpace.screen,
                  color: sl.divider,
                ),
                if (district == null)
                  for (final d in AppConstants.sriLankanDistricts)
                    _PickerTile(
                      label: d,
                      selected: false,
                      onTap: () => setState(() => _district = d),
                    )
                else ...[
                  if (widget.offerAllAreas)
                    _PickerTile(
                      label: l10n.homeAllAreas,
                      selected: widget.selectedCity == null,
                      onTap: () => navigator.pop(const _CityChoice()),
                    ),
                  for (final city in SriLankaLocations.citiesFor(district))
                    _PickerTile(
                      label: city,
                      selected: city == widget.selectedCity,
                      onTap: () => navigator.pop(
                        _CityChoice(district: district, city: city),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: SLSpace.screen),
      title: Text(
        label,
        style: context.slType.body.copyWith(
          color: selected ? sl.accentText : sl.ink,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: selected ? Icon(Icons.check, color: sl.accentText) : null,
      onTap: onTap,
    );
  }
}
