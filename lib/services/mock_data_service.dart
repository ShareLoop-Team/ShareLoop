import '../models/badge_model.dart';
import '../models/category_model.dart';
import '../models/exchange_model.dart';
import '../models/item_post_model.dart';
import '../models/item_request_model.dart';
import '../models/rating_review_model.dart';
import '../models/user_model.dart';

/// Service: single in-memory source of hard-coded ("mock") data, shared by
/// the mock repositories. The app has no data backend, so everything here
/// lasts for the current run only.
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
  final List<ExchangeModel> exchanges = [];

  /// Signed-in user; nobody until login/register, like a fresh install.
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
        title: 'Electric Pressure Cooker',
        description:
            'Stainless steel multi-cooker with presets for rice, soup, steam '
            'and slow cooking. All functions work; the inner pot and sealing '
            'ring are clean. Comes with the lid and power cord.',
        condition: 'Good',
        category: 'Household Items',
        district: 'Galle',
        city: 'Hikkaduwa',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        photoUrls: const ['assets/images/item_pressure_cooker.jpg'],
      ),
      ItemPostModel(
        id: 'p4',
        donorId: 'u4',
        donorName: 'Priya Rajan',
        title: 'Leather Wingtip Brogues (Size 9)',
        description:
            'Burgundy leather lace-up brogues with a pebbled wingtip toe. '
            'Worn twice for an event; soles and stitching are like new.',
        condition: 'Good',
        category: 'Shoes',
        district: 'Kandy',
        city: 'Peradeniya',
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
        photoUrls: const ['assets/images/item_leather_brogues.jpg'],
      ),
      ItemPostModel(
        id: 'p1',
        donorId: 'u1',
        donorName: 'Nimal Perera',
        title: 'Grade 10 Science Textbook',
        description:
            'Grade 10 Science textbook, "Exploring the Natural World". Used '
            'for one year but in good condition: no torn pages, only a few '
            'pencil notes that rub out easily.',
        condition: 'Good',
        category: 'Educational Books',
        district: 'Colombo',
        city: 'Nugegoda',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        photoUrls: const ['assets/images/item_grade10_science.jpg'],
      ),
      ItemPostModel(
        id: 'p2',
        donorId: 'u2',
        donorName: 'Kamani Silva',
        title: 'Leather School Backpack',
        description:
            'Maroon leather backpack with a large main compartment, a zipped '
            'front pocket and a side bottle holder. Barely used, all zips '
            'work smoothly.',
        condition: 'Good',
        category: 'School Supplies',
        district: 'Gampaha',
        city: 'Negombo',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        photoUrls: const ['assets/images/item_leather_backpack.jpg'],
      ),
      ItemPostModel(
        id: 'p3',
        donorId: 'u1',
        donorName: 'Nimal Perera',
        title: 'White Cotton T-Shirt',
        description:
            'Plain white crew-neck T-shirt, size M. Soft cotton, washed and '
            'ironed, no stains or holes.',
        condition: 'Used',
        category: 'Clothes',
        district: 'Colombo',
        city: 'Nugegoda',
        createdAt: DateTime.now().subtract(const Duration(hours: 10)),
        photoUrls: const ['assets/images/item_white_tshirt.jpg'],
      ),
      ItemPostModel(
        id: 'p6',
        donorId: 'u3',
        donorName: 'Sunil Fernando',
        title: 'Smartphone',
        description:
            'Full-screen smartphone in working condition. No cracks on the '
            'screen and the battery lasts a full day. Reset to factory '
            'settings; comes without a charger.',
        condition: 'Used',
        category: 'Electronics',
        district: 'Galle',
        city: 'Hikkaduwa',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        photoUrls: const ['assets/images/item_smartphone.jpg'],
      ),
      ItemPostModel(
        id: 'p7',
        donorId: 'u2',
        donorName: 'Kamani Silva',
        title: 'Slip-On Knit Sneakers (Size 8)',
        description:
            'Olive green knit sneakers with a cushioned white sole. Light and '
            'breathable, easy to slip on. Lightly worn, cleaned and no '
            'damage.',
        condition: 'Good',
        category: 'Shoes',
        district: 'Gampaha',
        city: 'Negombo',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        photoUrls: const ['assets/images/item_slip_on_sneakers.jpg'],
      ),
      ItemPostModel(
        id: 'p8',
        donorId: 'u4',
        donorName: 'Priya Rajan',
        title: 'Washed Grey Baseball Cap',
        description:
            'Vintage-wash grey cotton cap with an adjustable strap at the '
            'back. One size fits most. Washed and in great shape.',
        condition: 'Good',
        category: 'Clothes',
        district: 'Kandy',
        city: 'Peradeniya',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        photoUrls: const ['assets/images/item_grey_cap.jpg'],
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
      ItemRequestModel(
        id: 'r3',
        requesterId: 'u4',
        requesterName: 'Priya Rajan',
        itemName: 'School shoes, size 4',
        description: 'Black school shoes, size 4, any brand.',
        reason: "My daughter's shoes are worn out before the new term starts.",
        category: 'Shoes',
        district: 'Kandy',
        city: 'Peradeniya',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ItemRequestModel(
        id: 'r4',
        requesterId: 'u3',
        requesterName: 'Sunil Fernando',
        itemName: 'Study lamp',
        description: 'A rechargeable desk lamp for studying.',
        reason: 'Frequent power cuts at night and I need light to study.',
        category: 'Electronics',
        district: 'Galle',
        city: 'Hikkaduwa',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ItemRequestModel(
        id: 'r5',
        requesterId: 'u2',
        requesterName: 'Kamani Silva',
        itemName: 'Rice cooker',
        description: 'A small rice cooker in working condition.',
        reason: 'Moving into a new boarding place and starting with nothing.',
        category: 'Household Items',
        district: 'Gampaha',
        city: 'Negombo',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
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
  }
}
