import 'item_post_model.dart';

/// Available sort options for browsing the item catalog.
enum ItemSortOption {
  newest,
  oldest,
  highestRated,
  mostDonations,
  titleAsc,
}

/// Criteria for filtering and sorting the item catalog.
class ItemFilterCriteria {
  const ItemFilterCriteria({
    this.category,
    this.categories,
    this.condition,
    this.district,
    this.city,
    this.searchQuery = '',
    this.sortOption = ItemSortOption.newest,
    this.minDonorRating,
    this.status,
  });

  /// Single category filter (e.g. 'Educational Books').
  final String? category;

  /// Optional multi-category filter set.
  final Set<String>? categories;

  /// Item condition filter (e.g. 'New', 'Good', 'Used').
  final String? condition;

  /// Sri Lankan district filter.
  final String? district;

  /// City / area filter.
  final String? city;

  /// Free-text search matching across title, description, category,
  /// condition, location, and donor.
  final String searchQuery;

  /// How the filtered items should be ordered.
  final ItemSortOption sortOption;

  /// Minimum donor rating (e.g. 4.0).
  final double? minDonorRating;

  /// Post status filter (e.g. active, pending handover, completed).
  final ItemPostStatus? status;

  /// Whether any filter is narrowing the catalog results.
  bool get hasActiveFilters =>
      (category != null && category!.trim().isNotEmpty) ||
      (categories != null && categories!.isNotEmpty) ||
      (condition != null && condition!.trim().isNotEmpty) ||
      (district != null && district!.trim().isNotEmpty) ||
      (city != null && city!.trim().isNotEmpty) ||
      searchQuery.trim().isNotEmpty ||
      (minDonorRating != null && minDonorRating! > 0) ||
      sortOption != ItemSortOption.newest ||
      status != null;

  /// Checks if a single [ItemPostModel] meets all filter conditions.
  bool matches(ItemPostModel item) {
    // 1. Status filter
    if (status != null && item.status != status) {
      return false;
    }

    // 2. Category filter
    if (category != null && category!.trim().isNotEmpty) {
      if (item.category.toLowerCase() != category!.trim().toLowerCase()) {
        return false;
      }
    }
    if (categories != null && categories!.isNotEmpty) {
      final matchesAnyCategory = categories!.any(
        (c) => c.trim().toLowerCase() == item.category.toLowerCase(),
      );
      if (!matchesAnyCategory) return false;
    }

    // 3. Condition filter
    if (condition != null && condition!.trim().isNotEmpty) {
      if (item.condition.toLowerCase() != condition!.trim().toLowerCase()) {
        return false;
      }
    }

    // 4. District filter
    if (district != null && district!.trim().isNotEmpty) {
      if (item.district.toLowerCase() != district!.trim().toLowerCase()) {
        return false;
      }
    }

    // 5. City filter
    if (city != null && city!.trim().isNotEmpty) {
      if (item.city.toLowerCase() != city!.trim().toLowerCase()) {
        return false;
      }
    }

    // 6. Minimum donor rating
    if (minDonorRating != null && minDonorRating! > 0) {
      if (item.donorRating < minDonorRating!) {
        return false;
      }
    }

    // 7. Smart tokenized search query
    final trimmedQuery = searchQuery.trim();
    if (trimmedQuery.isNotEmpty) {
      final tokens = trimmedQuery
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty);

      for (final token in tokens) {
        final inTitle = item.title.toLowerCase().contains(token);
        final inDescription = item.description.toLowerCase().contains(token);
        final inCategory = item.category.toLowerCase().contains(token);
        final inCondition = item.condition.toLowerCase().contains(token);
        final inCity = item.city.toLowerCase().contains(token);
        final inDistrict = item.district.toLowerCase().contains(token);
        final inDonor = item.donorName.toLowerCase().contains(token);

        if (!inTitle &&
            !inDescription &&
            !inCategory &&
            !inCondition &&
            !inCity &&
            !inDistrict &&
            !inDonor) {
          return false;
        }
      }
    }

    return true;
  }

  /// Sorts [items] according to [sortOption].
  List<ItemPostModel> sortList(List<ItemPostModel> items) {
    final copy = List<ItemPostModel>.from(items);
    switch (sortOption) {
      case ItemSortOption.newest:
        copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ItemSortOption.oldest:
        copy.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case ItemSortOption.highestRated:
        copy.sort((a, b) {
          final cmp = b.donorRating.compareTo(a.donorRating);
          if (cmp != 0) return cmp;
          return b.createdAt.compareTo(a.createdAt);
        });
      case ItemSortOption.mostDonations:
        copy.sort((a, b) {
          final cmp = b.donorDonationCount.compareTo(a.donorDonationCount);
          if (cmp != 0) return cmp;
          return b.createdAt.compareTo(a.createdAt);
        });
      case ItemSortOption.titleAsc:
        copy.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return copy;
  }

  /// Filters and sorts a collection of items according to this criteria.
  List<ItemPostModel> filterAndSort(List<ItemPostModel> items) {
    return sortList(items.where(matches).toList());
  }

  ItemFilterCriteria copyWith({
    String? category,
    bool clearCategory = false,
    Set<String>? categories,
    bool clearCategories = false,
    String? condition,
    bool clearCondition = false,
    String? district,
    bool clearDistrict = false,
    String? city,
    bool clearCity = false,
    String? searchQuery,
    ItemSortOption? sortOption,
    double? minDonorRating,
    bool clearMinDonorRating = false,
    ItemPostStatus? status,
    bool clearStatus = false,
  }) {
    return ItemFilterCriteria(
      category: clearCategory ? null : (category ?? this.category),
      categories: clearCategories ? null : (categories ?? this.categories),
      condition: clearCondition ? null : (condition ?? this.condition),
      district: clearDistrict ? null : (district ?? this.district),
      city: clearCity ? null : (city ?? this.city),
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      minDonorRating: clearMinDonorRating
          ? null
          : (minDonorRating ?? this.minDonorRating),
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  /// A clean criteria with all filters reset to defaults.
  static const ItemFilterCriteria empty = ItemFilterCriteria();
}
