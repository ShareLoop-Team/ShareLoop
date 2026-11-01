import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shareloop/controllers/item_controller.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/core/theme/app_theme.dart';
import 'package:shareloop/models/item_post_model.dart';
import 'package:shareloop/repositories/item_post_repository.dart';
import 'package:shareloop/views/browse/search_filter_screen.dart';

/// Test repository that returns a fixed list of testing items.
class _TestingItemPostRepository implements ItemPostRepository {
  _TestingItemPostRepository(this.items);

  final List<ItemPostModel> items;

  @override
  Future<List<ItemPostModel>> getAllPosts({int limit = 50, int offset = 0}) async {
    return List.unmodifiable(items.skip(offset).take(limit));
  }

  @override
  Future<List<ItemPostModel>> getPostsByDonor(String donorId) async {
    return items.where((p) => p.donorId == donorId).toList();
  }

  @override
  Future<ItemPostModel?> getPostById(String id) async {
    return items.where((p) => p.id == id).firstOrNull;
  }

  @override
  Future<ItemPostModel> createPost(ItemPostModel post, {photos = const []}) async => post;

  @override
  Future<ItemPostModel> updatePost(ItemPostModel post, {newPhotos = const []}) async => post;

  @override
  Future<void> deletePost(String id) async {
    items.removeWhere((p) => p.id == id);
  }
}

/// Rich testing dataset representing catalog items across categories, conditions,
/// locations, donor stats, and post statuses.
List<ItemPostModel> _createTestingData() {
  final now = DateTime(2026, 11, 1, 10, 0, 0);

  return [
    ItemPostModel(
      id: 'item_1',
      donorId: 'donor_alice',
      donorName: 'Alice Silva',
      donorRating: 4.9,
      donorDonationCount: 30,
      title: 'Grade 10 Science Textbook',
      description: 'Comprehensive science textbook with diagrams. Very neat condition.',
      category: 'Educational Books',
      condition: 'Good',
      district: 'Colombo',
      city: 'Nugegoda',
      createdAt: now.subtract(const Duration(hours: 1)),
      status: ItemPostStatus.active,
    ),
    ItemPostModel(
      id: 'item_2',
      donorId: 'donor_bob',
      donorName: 'Bob Perera',
      donorRating: 4.2,
      donorDonationCount: 8,
      title: 'Mathematics Revision Workbook',
      description: 'Practice questions for O/L exams. Completely unused.',
      category: 'Educational Books',
      condition: 'New',
      district: 'Colombo',
      city: 'Dehiwala',
      createdAt: now.subtract(const Duration(hours: 5)),
      status: ItemPostStatus.active,
    ),
    ItemPostModel(
      id: 'item_3',
      donorId: 'donor_alice',
      donorName: 'Alice Silva',
      donorRating: 4.9,
      donorDonationCount: 30,
      title: 'Leather School Backpack',
      description: 'Durable brown leather backpack with multiple compartments.',
      category: 'School Supplies',
      condition: 'Good',
      district: 'Gampaha',
      city: 'Negombo',
      createdAt: now.subtract(const Duration(hours: 2)),
      status: ItemPostStatus.active,
    ),
    ItemPostModel(
      id: 'item_4',
      donorId: 'donor_charlie',
      donorName: 'Charlie Fernando',
      donorRating: 3.8,
      donorDonationCount: 2,
      title: 'Cotton Crew-Neck T-Shirt',
      description: 'Size M white plain cotton t-shirt. Cleaned and ironed.',
      category: 'Clothes',
      condition: 'Used',
      district: 'Kandy',
      city: 'Peradeniya',
      createdAt: now.subtract(const Duration(hours: 8)),
      status: ItemPostStatus.active,
    ),
    ItemPostModel(
      id: 'item_5',
      donorId: 'donor_david',
      donorName: 'David Rajan',
      donorRating: 4.7,
      donorDonationCount: 15,
      title: 'Leather Wingtip Shoes',
      description: 'Formal burgundy leather shoes, size 9.',
      category: 'Shoes',
      condition: 'Good',
      district: 'Kandy',
      city: 'Peradeniya',
      createdAt: now.subtract(const Duration(hours: 12)),
      status: ItemPostStatus.active,
    ),
    ItemPostModel(
      id: 'item_6',
      donorId: 'donor_eve',
      donorName: 'Eve Wickramasinghe',
      donorRating: 5.0,
      donorDonationCount: 45,
      title: 'Electric Pressure Cooker',
      description: 'Stainless steel multi-cooker. Inner pot is brand new.',
      category: 'Household Items',
      condition: 'New',
      district: 'Galle',
      city: 'Hikkaduwa',
      createdAt: now.subtract(const Duration(hours: 3)),
      status: ItemPostStatus.active,
    ),
    ItemPostModel(
      id: 'item_7',
      donorId: 'donor_frank',
      donorName: 'Frank Dias',
      donorRating: 4.0,
      donorDonationCount: 4,
      title: 'Android Smartphone',
      description: 'Full-screen mobile phone in working condition with clean display.',
      category: 'Electronics',
      condition: 'Used',
      district: 'Galle',
      city: 'Galle',
      createdAt: now.subtract(const Duration(hours: 20)),
      status: ItemPostStatus.active,
    ),
    ItemPostModel(
      id: 'item_8',
      donorId: 'donor_alice',
      donorName: 'Alice Silva',
      donorRating: 4.9,
      donorDonationCount: 30,
      title: 'Vintage Denim Jacket',
      description: 'Classic blue denim jacket, size L. Great condition.',
      category: 'Clothes',
      condition: 'Good',
      district: 'Colombo',
      city: 'Nugegoda',
      createdAt: now.subtract(const Duration(hours: 24)),
      status: ItemPostStatus.pendingHandover, // Pending handover
    ),
    ItemPostModel(
      id: 'item_9',
      donorId: 'donor_bob',
      donorName: 'Bob Perera',
      donorRating: 4.2,
      donorDonationCount: 8,
      title: 'Wooden Study Desk',
      description: 'Solid teak study table. Handover already finished.',
      category: 'Household Items',
      condition: 'Used',
      district: 'Colombo',
      city: 'Nugegoda',
      createdAt: now.subtract(const Duration(hours: 48)),
      status: ItemPostStatus.completed, // Completed
    ),
  ];
}

void main() {
  late List<ItemPostModel> testItems;
  late ItemFilterCriteria defaultCriteria;

  setUp(() {
    testItems = _createTestingData();
    defaultCriteria = ItemFilterCriteria.empty;
  });

  group('ItemFilterCriteria Unit Tests with Testing Data', () {
    test('default criteria returns all active and non-active items matching criteria', () {
      final results = defaultCriteria.filterAndSort(testItems);
      expect(results.length, equals(9));
    });

    test('filters accurately by category', () {
      const criteria = ItemFilterCriteria(category: 'Educational Books');
      final results = criteria.filterAndSort(testItems);

      expect(results.length, equals(2));
      expect(results.every((item) => item.category == 'Educational Books'), isTrue);
      expect(results.map((i) => i.id), containsAll(['item_1', 'item_2']));
    });

    test('category filter is case-insensitive and trims whitespace', () {
      const criteria = ItemFilterCriteria(category: '  educational books  ');
      final results = criteria.filterAndSort(testItems);

      expect(results.length, equals(2));
    });

    test('multi-category filter matches items from any specified category', () {
      const criteria = ItemFilterCriteria(
        categories: {'Educational Books', 'Electronics'},
      );
      final results = criteria.filterAndSort(testItems);

      expect(results.length, equals(3));
      expect(results.map((i) => i.id), containsAll(['item_1', 'item_2', 'item_7']));
    });

    test('filters accurately by condition (New, Good, Used)', () {
      const newCriteria = ItemFilterCriteria(condition: 'New');
      final newResults = newCriteria.filterAndSort(testItems);
      expect(newResults.length, equals(2));
      expect(newResults.every((i) => i.condition == 'New'), isTrue);
      expect(newResults.map((i) => i.id), containsAll(['item_2', 'item_6']));

      const goodCriteria = ItemFilterCriteria(condition: 'Good');
      final goodResults = goodCriteria.filterAndSort(testItems);
      expect(goodResults.length, equals(4));
      expect(goodResults.every((i) => i.condition == 'Good'), isTrue);

      const usedCriteria = ItemFilterCriteria(condition: 'Used');
      final usedResults = usedCriteria.filterAndSort(testItems);
      expect(usedResults.length, equals(3));
      expect(usedResults.every((i) => i.condition == 'Used'), isTrue);
    });

    test('filters accurately by district and city', () {
      // Colombo district (includes Nugegoda and Dehiwala)
      const colomboCriteria = ItemFilterCriteria(district: 'Colombo');
      final colomboResults = colomboCriteria.filterAndSort(testItems);
      expect(colomboResults.length, equals(4));

      // Nugegoda city only
      const nugegodaCriteria = ItemFilterCriteria(district: 'Colombo', city: 'Nugegoda');
      final nugegodaResults = nugegodaCriteria.filterAndSort(testItems);
      expect(nugegodaResults.length, equals(3));
      expect(nugegodaResults.every((i) => i.city == 'Nugegoda'), isTrue);

      // Kandy district
      const kandyCriteria = ItemFilterCriteria(district: 'Kandy');
      final kandyResults = kandyCriteria.filterAndSort(testItems);
      expect(kandyResults.length, equals(2));
    });

    test('filters accurately by minimum donor rating', () {
      const ratingCriteria = ItemFilterCriteria(minDonorRating: 4.5);
      final results = ratingCriteria.filterAndSort(testItems);

      // Alice (4.9), David (4.7), Eve (5.0)
      expect(results.every((i) => i.donorRating >= 4.5), isTrue);
      expect(results.any((i) => i.donorRating < 4.5), isFalse);
    });

    test('filters accurately by item post status', () {
      const activeCriteria = ItemFilterCriteria(status: ItemPostStatus.active);
      final activeResults = activeCriteria.filterAndSort(testItems);
      expect(activeResults.length, equals(7));
      expect(activeResults.every((i) => i.status == ItemPostStatus.active), isTrue);

      const pendingCriteria = ItemFilterCriteria(status: ItemPostStatus.pendingHandover);
      final pendingResults = pendingCriteria.filterAndSort(testItems);
      expect(pendingResults.length, equals(1));
      expect(pendingResults.first.id, equals('item_8'));
    });

    group('Smart Multi-Field Tokenized Search', () {
      test('searches by title keywords', () {
        const criteria = ItemFilterCriteria(searchQuery: 'Science');
        final results = criteria.filterAndSort(testItems);
        expect(results.length, equals(1));
        expect(results.first.id, equals('item_1'));
      });

      test('searches by description content', () {
        const criteria = ItemFilterCriteria(searchQuery: 'stainless steel');
        final results = criteria.filterAndSort(testItems);
        expect(results.length, equals(1));
        expect(results.first.id, equals('item_6'));
      });

      test('searches across category name', () {
        const criteria = ItemFilterCriteria(searchQuery: 'Electronics');
        final results = criteria.filterAndSort(testItems);
        expect(results.length, equals(1));
        expect(results.first.id, equals('item_7'));
      });

      test('searches across donor name', () {
        const criteria = ItemFilterCriteria(searchQuery: 'Alice Silva');
        final results = criteria.filterAndSort(testItems);
        expect(results.length, equals(3));
        expect(results.every((i) => i.donorName == 'Alice Silva'), isTrue);
      });

      test('multi-token search matches across different fields (e.g. leather + negombo)', () {
        // "leather" is in title, "negombo" is in city
        const criteria = ItemFilterCriteria(searchQuery: 'leather negombo');
        final results = criteria.filterAndSort(testItems);
        expect(results.length, equals(1));
        expect(results.first.id, equals('item_3'));
      });

      test('search handles case-insensitivity and multiple whitespace', () {
        const criteria = ItemFilterCriteria(searchQuery: '   wInGtIp   kAnDy   ');
        final results = criteria.filterAndSort(testItems);
        expect(results.length, equals(1));
        expect(results.first.id, equals('item_5'));
      });

      test('search returns empty when no items match', () {
        const criteria = ItemFilterCriteria(searchQuery: 'nonexistent keyword xyz');
        final results = criteria.filterAndSort(testItems);
        expect(results, isEmpty);
      });
    });

    group('Sorting Options with Testing Data', () {
      test('sorts by newest first (default)', () {
        const criteria = ItemFilterCriteria(sortOption: ItemSortOption.newest);
        final results = criteria.filterAndSort(testItems);

        for (var i = 0; i < results.length - 1; i++) {
          expect(results[i].createdAt.isAfter(results[i + 1].createdAt) ||
                 results[i].createdAt.isAtSameMomentAs(results[i + 1].createdAt), isTrue);
        }
      });

      test('sorts by oldest first', () {
        const criteria = ItemFilterCriteria(sortOption: ItemSortOption.oldest);
        final results = criteria.filterAndSort(testItems);

        for (var i = 0; i < results.length - 1; i++) {
          expect(results[i].createdAt.isBefore(results[i + 1].createdAt) ||
                 results[i].createdAt.isAtSameMomentAs(results[i + 1].createdAt), isTrue);
        }
      });

      test('sorts by highest rated donor first', () {
        const criteria = ItemFilterCriteria(sortOption: ItemSortOption.highestRated);
        final results = criteria.filterAndSort(testItems);

        expect(results.first.donorRating, equals(5.0)); // Eve (5.0)
        for (var i = 0; i < results.length - 1; i++) {
          expect(results[i].donorRating >= results[i + 1].donorRating, isTrue);
        }
      });

      test('sorts by most donations first', () {
        const criteria = ItemFilterCriteria(sortOption: ItemSortOption.mostDonations);
        final results = criteria.filterAndSort(testItems);

        expect(results.first.donorDonationCount, equals(45)); // Eve (45)
        for (var i = 0; i < results.length - 1; i++) {
          expect(results[i].donorDonationCount >= results[i + 1].donorDonationCount, isTrue);
        }
      });

      test('sorts alphabetically by title (A-Z)', () {
        const criteria = ItemFilterCriteria(sortOption: ItemSortOption.titleAsc);
        final results = criteria.filterAndSort(testItems);

        expect(results.first.title, equals('Android Smartphone'));
        expect(results.last.title, equals('Wooden Study Desk'));
      });
    });

    test('combined filtering: category + condition + location + sort', () {
      // Books in Colombo that are Good condition, sorted by newest
      const criteria = ItemFilterCriteria(
        category: 'Educational Books',
        condition: 'Good',
        district: 'Colombo',
        city: 'Nugegoda',
        sortOption: ItemSortOption.newest,
      );

      final results = criteria.filterAndSort(testItems);
      expect(results.length, equals(1));
      expect(results.first.id, equals('item_1'));
      expect(results.first.title, equals('Grade 10 Science Textbook'));
    });
  });

  group('ItemController Integration with Testing Data', () {
    late ItemController controller;

    setUp(() async {
      final repo = _TestingItemPostRepository(List.from(testItems));
      controller = ItemController(repository: repo);
      await controller.loadPosts();
    });

    test('loads posts and exposes availablePosts vs posts correctly', () {
      expect(controller.posts.length, equals(9));
      expect(controller.availablePosts.length, equals(7)); // Only active posts
    });

    test('setting category filter updates posts and notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.setCategoryFilter('Shoes');

      expect(notified, isTrue);
      expect(controller.categoryFilter, equals('Shoes'));
      expect(controller.availablePosts.length, equals(1));
      expect(controller.availablePosts.first.title, equals('Leather Wingtip Shoes'));
    });

    test('setting condition filter updates posts and notifies listeners', () {
      controller.setConditionFilter('New');

      expect(controller.conditionFilter, equals('New'));
      expect(controller.availablePosts.length, equals(2));
      expect(controller.availablePosts.every((i) => i.condition == 'New'), isTrue);
    });

    test('setting search query updates posts with tokenized multi-field matching', () {
      controller.setSearchQuery('shoes peradeniya');

      expect(controller.availablePosts.length, equals(1));
      expect(controller.availablePosts.first.id, equals('item_5'));
    });

    test('setting sort option changes the order of available posts', () {
      controller.setSortOption(ItemSortOption.highestRated);

      final firstPost = controller.availablePosts.first;
      expect(firstPost.donorRating, equals(5.0)); // Eve (5.0)
    });

    test('hasActiveFilters reflects changes and clearFilters resets everything', () {
      expect(controller.hasActiveFilters, isFalse);

      controller.setCategoryFilter('Clothes');
      expect(controller.hasActiveFilters, isTrue);

      controller.setConditionFilter('Good');
      controller.setSearchQuery('vintage');

      expect(controller.availablePosts.length, equals(0)); // Only active clothes is Used; pending one is Good

      controller.clearFilters();
      expect(controller.hasActiveFilters, isFalse);
      expect(controller.categoryFilter, isNull);
      expect(controller.conditionFilter, isNull);
      expect(controller.searchQuery, isEmpty);
      expect(controller.availablePosts.length, equals(7));
    });

    test('filterItems helper executes custom criteria without changing controller state', () {
      const customCriteria = ItemFilterCriteria(condition: 'New');
      final filtered = controller.filterItems(controller.allPosts, criteria: customCriteria);

      expect(filtered.length, equals(2));
      expect(controller.hasActiveFilters, isFalse); // Controller state untouched
    });
  });

  group('SearchFilterScreen Widget Tests with Testing Data', () {
    testWidgets('displays filters, allows selecting condition and applying to controller', (
      tester,
    ) async {
      final repo = _TestingItemPostRepository(List.from(testItems));
      final controller = ItemController(repository: repo);
      await controller.loadPosts();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ItemController>.value(value: controller),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SearchFilterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title and sections exist
      expect(find.text('Filter Catalog'), findsOneWidget);
      expect(find.text('Sort By'), findsOneWidget);
      expect(find.text('Item Condition'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);

      // Condition chips
      expect(find.text('All Conditions'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Used'), findsOneWidget);

      // Select 'New' condition
      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();

      // Show button should reflect 2 matching items (item_2, item_6)
      expect(find.text('Show 2 Items'), findsOneWidget);

      // Tap Apply button
      await tester.tap(find.text('Show 2 Items'));
      await tester.pumpAndSettle();

      // Controller should now have condition 'New' applied!
      expect(controller.conditionFilter, equals('New'));
      expect(controller.availablePosts.length, equals(2));
    });

    testWidgets('allows resetting filters via Reset button', (tester) async {
      final repo = _TestingItemPostRepository(List.from(testItems));
      final controller = ItemController(repository: repo);
      await controller.loadPosts();
      controller.setCategoryFilter('Shoes');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ItemController>.value(value: controller),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SearchFilterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Reset button
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Apply button should now show all 7 active items
      expect(find.text('Show 7 Items'), findsOneWidget);
    });
  });
}
