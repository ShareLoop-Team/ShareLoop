import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/item_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/sri_lanka_locations.dart';
import '../../core/theme/sl_tokens.dart';
import '../../models/item_post_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/sl/sl_chip.dart';

/// View: advanced filter screen for catalog items (category, condition,
/// district, city, donor rating, and sort order).
class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  String? _category;
  String? _condition;
  String? _district;
  String? _city;
  ItemSortOption _sortOption = ItemSortOption.newest;
  double? _minRating;

  @override
  void initState() {
    super.initState();
    final criteria = context.read<ItemController>().filterCriteria;
    _category = criteria.category;
    _condition = criteria.condition;
    _district = criteria.district;
    _city = criteria.city;
    _sortOption = criteria.sortOption;
    _minRating = criteria.minDonorRating;
  }

  ItemFilterCriteria _currentDraftCriteria(ItemController controller) {
    return controller.filterCriteria.copyWith(
      category: _category,
      clearCategory: _category == null,
      condition: _condition,
      clearCondition: _condition == null,
      district: _district,
      clearDistrict: _district == null,
      city: _city,
      clearCity: _city == null,
      sortOption: _sortOption,
      minDonorRating: _minRating,
      clearMinDonorRating: _minRating == null,
    );
  }

  void _clearAll() {
    setState(() {
      _category = null;
      _condition = null;
      _district = null;
      _city = null;
      _sortOption = ItemSortOption.newest;
      _minRating = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    final type = context.slType;
    final controller = context.watch<ItemController>();

    final draftCriteria = _currentDraftCriteria(controller);
    final matchCount = controller.filterItems(
      controller.allPosts,
      criteria: draftCriteria.copyWith(status: ItemPostStatus.active),
    ).length;

    final availableCities = SriLankaLocations.citiesFor(_district);

    return Scaffold(
      backgroundColor: sl.ground,
      appBar: AppBar(
        title: const Text('Filter Catalog'),
        backgroundColor: sl.ground,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _clearAll,
            child: Text(
              'Reset',
              style: type.body.copyWith(
                color: sl.accentText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: SLSpace.screen,
                  vertical: SLSpace.m,
                ),
                children: [
                  // 1. Sort by
                  _SectionTitle(title: 'Sort By', type: type, sl: sl),
                  const SizedBox(height: SLSpace.s),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChoiceChip(
                        label: 'Newest',
                        selected: _sortOption == ItemSortOption.newest,
                        onTap: () => setState(
                          () => _sortOption = ItemSortOption.newest,
                        ),
                      ),
                      _FilterChoiceChip(
                        label: 'Top Rated Donor',
                        selected: _sortOption == ItemSortOption.highestRated,
                        onTap: () => setState(
                          () => _sortOption = ItemSortOption.highestRated,
                        ),
                      ),
                      _FilterChoiceChip(
                        label: 'Most Donations',
                        selected: _sortOption == ItemSortOption.mostDonations,
                        onTap: () => setState(
                          () => _sortOption = ItemSortOption.mostDonations,
                        ),
                      ),
                      _FilterChoiceChip(
                        label: 'Name (A–Z)',
                        selected: _sortOption == ItemSortOption.titleAsc,
                        onTap: () => setState(
                          () => _sortOption = ItemSortOption.titleAsc,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SLSpace.l),

                  // 2. Condition
                  _SectionTitle(title: 'Item Condition', type: type, sl: sl),
                  const SizedBox(height: SLSpace.s),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChoiceChip(
                        label: 'All Conditions',
                        selected: _condition == null,
                        onTap: () => setState(() => _condition = null),
                      ),
                      for (final cond in AppConstants.itemConditions)
                        _FilterChoiceChip(
                          label: cond,
                          selected: _condition == cond,
                          onTap: () => setState(
                            () => _condition = _condition == cond ? null : cond,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: SLSpace.l),

                  // 3. Category
                  _SectionTitle(title: 'Category', type: type, sl: sl),
                  const SizedBox(height: SLSpace.s),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChoiceChip(
                        label: 'All Categories',
                        selected: _category == null,
                        onTap: () => setState(() => _category = null),
                      ),
                      for (final cat in AppConstants.itemCategories)
                        _FilterChoiceChip(
                          label: cat,
                          selected: _category == cat,
                          onTap: () => setState(
                            () => _category = _category == cat ? null : cat,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: SLSpace.l),

                  // 4. Location (District & City)
                  _SectionTitle(title: 'Location', type: type, sl: sl),
                  const SizedBox(height: SLSpace.s),
                  DropdownButtonFormField<String?>(
                    initialValue: _district,
                    decoration: InputDecoration(
                      labelText: 'District',
                      filled: true,
                      fillColor: sl.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(SLRadius.control),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Districts'),
                      ),
                      ...AppConstants.sriLankanDistricts.map(
                        (d) => DropdownMenuItem(value: d, child: Text(d)),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _district = val;
                        if (!SriLankaLocations.isCityIn(val, _city)) {
                          _city = null;
                        }
                      });
                    },
                  ),
                  if (availableCities.isNotEmpty) ...[
                    const SizedBox(height: SLSpace.s),
                    DropdownButtonFormField<String?>(
                      initialValue: _city,
                      decoration: InputDecoration(
                        labelText: 'City / Area',
                        filled: true,
                        fillColor: sl.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SLRadius.control),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Cities'),
                        ),
                        ...availableCities.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        ),
                      ],
                      onChanged: (val) => setState(() => _city = val),
                    ),
                  ],
                  const SizedBox(height: SLSpace.l),

                  // 5. Donor Rating
                  _SectionTitle(title: 'Donor Rating', type: type, sl: sl),
                  const SizedBox(height: SLSpace.s),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChoiceChip(
                        label: 'Any Rating',
                        selected: _minRating == null,
                        onTap: () => setState(() => _minRating = null),
                      ),
                      _FilterChoiceChip(
                        label: '★ 4.0 & above',
                        selected: _minRating == 4.0,
                        onTap: () => setState(
                          () => _minRating = _minRating == 4.0 ? null : 4.0,
                        ),
                      ),
                      _FilterChoiceChip(
                        label: '★ 4.5 & above',
                        selected: _minRating == 4.5,
                        onTap: () => setState(
                          () => _minRating = _minRating == 4.5 ? null : 4.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SLSpace.xl),
                ],
              ),
            ),

            // Bottom bar with match count & apply button
            Container(
              padding: const EdgeInsets.all(SLSpace.screen),
              decoration: BoxDecoration(
                color: sl.surface,
                border: Border(top: BorderSide(color: sl.divider)),
              ),
              child: CustomButton(
                label: 'Show $matchCount Items',
                onPressed: () {
                  final itemController = context.read<ItemController>();
                  itemController.setFilterCriteria(
                    _currentDraftCriteria(itemController),
                  );
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.type,
    required this.sl,
  });

  final String title;
  final dynamic type;
  final SLColors sl;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: type.body.copyWith(
        fontWeight: FontWeight.bold,
        color: sl.ink,
      ),
    );
  }
}

class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SLChip(
      label: label,
      selected: selected,
      onTap: onTap,
    );
  }
}
