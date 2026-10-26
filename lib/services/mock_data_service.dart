import '../models/badge_model.dart';
import '../models/category_model.dart';
import '../models/item_post_model.dart';
import '../models/item_request_model.dart';
import '../models/rating_review_model.dart';
import '../models/user_model.dart';

/// Service: single in-memory source of hard-coded ("mock") data, shared by
/// all repositories. Stands in for a REST API/database today — repositories
/// depend on this service, not the other way around, so swapping it for a
/// real HTTP client later requires no controller or view changes.
class MockDataService {
  MockDataService._internal() {
    _seed();
  }

  static final MockDataService instance = MockDataService._internal();

  final List<UserModel> users = [];
  final List<ItemPostModel> itemPosts = [];
  final List<ItemRequestModel> itemRequests = [];
  final List<RatingReviewModel> ratings = [];
  final List<CategoryModel> categories = [];
  final List<BadgeModel> badges = [];

  String? currentUserId;

  void _seed() {
    users.addAll([
      const UserModel(
        id: 'u1',
        name: 'Nimal Perera',
        email: 'nimal@example.com',
        phone: '0771234567',
        district: 'Colombo',
        city: 'Nugegoda',
        donationCount: 12,
        averageRating: 4.6,
        ratingCount: 9,
      ),
      const UserModel(
        id: 'u2',
        name: 'Kamani Silva',
        email: 'kamani@example.com',
        phone: '0719876543',
        district: 'Gampaha',
        city: 'Negombo',
        donationCount: 3,
        averageRating: 4.9,
        ratingCount: 2,
      ),
      const UserModel(
        id: 'u3',
        name: 'Sunil Fernando',
        email: 'sunil@example.com',
        phone: '0761122334',
        district: 'Galle',
        city: 'Hikkaduwa',
        donationCount: 27,
        averageRating: 4.8,
        ratingCount: 21,
      ),
      const UserModel(
        id: 'u4',
        name: 'Priya Rajan',
        email: 'priya@example.com',
        phone: '0705566778',
        district: 'Kandy',
        city: 'Peradeniya',
        donationCount: 6,
        averageRating: 4.5,
        ratingCount: 4,
      ),
      const UserModel(
        id: 'admin1',
        name: 'Platform Admin',
        email: 'admin@shareloop.lk',
        phone: '0112223344',
        district: 'Colombo',
        city: 'Colombo 01',
        isAdmin: true,
      ),
    ]);

    categories.addAll(const [
      CategoryModel(id: 'books', name: 'Educational Books', iconName: 'book'),
      CategoryModel(
          id: 'supplies', name: 'School Supplies', iconName: 'edit'),
      CategoryModel(id: 'clothes', name: 'Clothes', iconName: 'checkroom'),
      CategoryModel(
          id: 'shoes', name: 'Shoes', iconName: 'sports_soccer'),
      CategoryModel(
          id: 'electronics', name: 'Electronics', iconName: 'devices'),
      CategoryModel(
          id: 'household', name: 'Household Items', iconName: 'chair'),
      CategoryModel(id: 'other', name: 'Other', iconName: 'category'),
    ]);

    badges.addAll(const [
      BadgeModel(
          name: 'Bronze', requiredDonations: 5, level: 'New Contributor'),
      BadgeModel(
          name: 'Silver', requiredDonations: 10, level: 'Active Contributor'),
      BadgeModel(
          name: 'Gold', requiredDonations: 25, level: 'Trusted Contributor'),
      BadgeModel(
          name: 'Platinum',
          requiredDonations: 50,
          level: 'Community Champion'),
    ]);

    // Oldest first: the repository lists the most recently added first.
    itemPosts.addAll([
      ItemPostModel(
        id: 'p5',
        donorId: 'u3',
        donorName: 'Sunil Fernando',
        title: 'Rice Cooker',
        description: '1.8L rice cooker, works perfectly.',
        condition: 'Good',
        category: 'Household Items',
        district: 'Galle',
        city: 'Hikkaduwa',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      ItemPostModel(
        id: 'p4',
        donorId: 'u4',
        donorName: 'Priya Rajan',
        title: 'Black School Shoes (Size 6)',
        description: 'Brand new, bought the wrong size.',
        condition: 'New',
        category: 'Shoes',
        district: 'Kandy',
        city: 'Peradeniya',
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      ),
      ItemPostModel(
        id: 'p1',
        donorId: 'u1',
        donorName: 'Nimal Perera',
        title: 'Grade 10 Science Textbook',
        description: 'Used but in good condition, no torn pages.',
        condition: 'Good',
        category: 'Educational Books',
        district: 'Colombo',
        city: 'Nugegoda',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ItemPostModel(
        id: 'p2',
        donorId: 'u2',
        donorName: 'Kamani Silva',
        title: 'Kids School Bag',
        description: 'Barely used, blue colour, good zips.',
        condition: 'Good',
        category: 'School Supplies',
        district: 'Gampaha',
        city: 'Negombo',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ItemPostModel(
        id: 'p3',
        donorId: 'u1',
        donorName: 'Nimal Perera',
        title: 'Men\'s Office Shirts (3)',
        description: 'Washed and ironed, sizes M.',
        condition: 'Used',
        category: 'Clothes',
        district: 'Colombo',
        city: 'Nugegoda',
        createdAt: DateTime.now().subtract(const Duration(hours: 10)),
      ),
    ]);

    itemRequests.addAll([
      ItemRequestModel(
        id: 'r1',
        requesterId: 'u2',
        requesterName: 'Kamani Silva',
        itemPostId: 'p1',
        description: 'Grade 10 science textbook',
        reason: 'My child lost their textbook and exams are approaching.',
        category: 'Educational Books',
        district: 'Gampaha',
        city: 'Negombo',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ItemRequestModel(
        id: 'r2',
        requesterId: 'u1',
        requesterName: 'Nimal Perera',
        description: 'Grade 5 A/L notes for Maths',
        reason: 'Preparing for scholarship exam, cannot afford tuition notes.',
        category: 'Educational Books',
        district: 'Colombo',
        city: 'Nugegoda',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ]);

    ratings.addAll([
      RatingReviewModel(
        id: 'rv1',
        itemPostId: 'p1',
        raterId: 'u2',
        rateeId: 'u1',
        stars: 5,
        comment: 'Very kind donor, smooth handover!',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ]);

    currentUserId = 'u1';
  }
}
