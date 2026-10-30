import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/item_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/request_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/sri_lanka_locations.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../models/user_model.dart';
import '../../widgets/category_circle.dart';
import '../../widgets/use_my_location.dart';
import '../../widgets/user_avatar.dart';
import 'give_away_tab.dart';

/// View: the Home tab — greeting, search, photo category circles, and the
/// matching Give Away items near you. Filters live in [ItemController].
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
    final profileCity =
        SriLankaLocations.validCity(profileDistrict, user?.city);

    final choice = await showModalBottomSheet<_CityChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
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
    final saved =
        await _saveCity(l10n, user, district: match.district, city: city);
    if (!saved || !mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.locationDetected(city, match.district))),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final itemController = context.watch<ItemController>();
    final user = context.watch<AuthController>().currentUser;
    final firstName = user?.name.trim().split(' ').first ?? '';

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
      cityLabel = itemController.cityFilter ??
          (profileCity == null ? l10n.homeSelectCity : l10n.homeAllAreas);
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          // Scrolling the results puts the search keyboard away.
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverList.list(
                children: [
                  _Header(
                    greeting: firstName.isEmpty
                        ? l10n.homeGreetingGuest
                        : l10n.homeGreeting(firstName),
                    avatarUrl: user?.avatarUrl,
                    onProfileTap: widget.onOpenProfile,
                  ),
                  const SizedBox(height: 16),
                  _SearchField(
                    controller: _searchController,
                    hint: l10n.homeSearchHint,
                    clearTooltip: l10n.searchClear,
                    onChanged: itemController.setSearchQuery,
                    onClear: _clearSearch,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.homeCategories,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: CategoryCirclesRow(
                allLabel: l10n.homeAllCategories,
                selected: itemController.categoryFilter,
                onSelected: itemController.setCategoryFilter,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.homeAvailableNearYou,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Long Sinhala/Tamil names shrink instead of overflowing.
                    Flexible(
                      child: _LocationButton(
                        label: cityLabel,
                        onTap: () => _showCityPicker(l10n, user),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GiveAwayTab(onClearFilters: _clearFilters),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.avatarUrl,
    required this.onProfileTap,
  });

  final String greeting;

  /// The signed-in user's photo; a person icon is shown without one.
  final String? avatarUrl;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final avatarRadius = BorderRadius.circular(16);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A large two-tone wordmark, no icon.
              Semantics(
                label: 'ShareLoop',
                header: true,
                excludeSemantics: true,
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
                    style: textTheme.headlineLarge?.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.1,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                greeting,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Tooltip(
          message: AppLocalizations.of(context).profile,
          child: Semantics(
            button: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onProfileTap,
                borderRadius: avatarRadius,
                child: (avatarUrl?.isNotEmpty ?? false)
                    ? UserAvatar(
                        url: avatarUrl,
                        size: 60,
                        ringWidth: 2,
                        borderRadius: avatarRadius,
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: avatarRadius,
                          border: Border.all(color: AppColors.softMint),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 28,
                          color: AppColors.deepGreen,
                        ),
                      ),
              ),
            ),
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
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        // The parent rebuilds on every search change, so this tracks the
        // text without its own listener.
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                tooltip: clearTooltip,
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
              ),
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

class _LocationButton extends StatelessWidget {
  const _LocationButton({required this.label, required this.onTap});

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
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.deepGreen,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
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
    final textTheme = Theme.of(context).textTheme;
    final district = _district;
    final navigator = Navigator.of(context);

    return FractionallySizedBox(
      heightFactor: 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              district == null ? l10n.homeChooseDistrict : l10n.homeChooseCity,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (widget.note case final note?)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
              child: Text(
                note,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.deepGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (district != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.homeCityDistrict(district),
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _district = null),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.deepGreen,
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.deepGreen,
                  ),
                  title: Text(
                    l10n.locationUseMine,
                    style: const TextStyle(
                      color: AppColors.deepGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () =>
                      navigator.pop(const _CityChoice.useMyLocation()),
                ),
                const Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: AppColors.border,
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
