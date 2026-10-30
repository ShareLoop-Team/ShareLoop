import 'package:flutter_test/flutter_test.dart';

import 'package:shareloop/controllers/auth_controller.dart';
import 'package:shareloop/controllers/item_controller.dart';
import 'package:shareloop/controllers/request_controller.dart';
import 'package:shareloop/controllers/splash_controller.dart';
import 'package:shareloop/core/routes/app_routes.dart';
import 'package:shareloop/models/item_post_model.dart';
import 'package:shareloop/models/item_request_model.dart';
import 'package:shareloop/services/mock_data_service.dart';

/// The mock store is shared within this file, so each test makes its own
/// post (donor Nimal, u1) and request (requester Kamani, u2).
Future<(String postId, String requestId)> _postWithRequest(String id) async {
  final data = MockDataService.instance;
  data.itemPosts.add(ItemPostModel(
    id: 'post-$id',
    donorId: 'u1',
    donorName: 'Nimal Perera',
    title: 'Lamp $id',
    description: 'Works fine.',
    condition: 'Good',
    category: 'Electronics',
    district: 'Colombo',
    city: 'Nugegoda',
    createdAt: DateTime.now(),
  ));
  data.itemRequests.add(ItemRequestModel(
    id: 'req-$id',
    requesterId: 'u2',
    requesterName: 'Kamani Silva',
    itemPostId: 'post-$id',
    description: 'Need a lamp',
    reason: 'Power cuts',
    category: 'Electronics',
    district: 'Gampaha',
    city: 'Negombo',
    createdAt: DateTime.now(),
  ));
  return ('post-$id', 'req-$id');
}

ItemPostModel _post(String id) =>
    MockDataService.instance.itemPosts.firstWhere((p) => p.id == id);

ItemRequestModel _request(String id) =>
    MockDataService.instance.itemRequests.firstWhere((r) => r.id == id);

int _donations(String userId) => MockDataService.instance.users
    .firstWhere((u) => u.id == userId)
    .donationCount;

void main() {
  test('selecting a request records the requester, not the request id',
      () async {
    final (postId, requestId) = await _postWithRequest('select');
    final auth = AuthController();
    await auth.login('nimal@example.com', 'x');

    final error = await ItemController().selectRequester(postId, requestId);

    expect(error, isNull);
    expect(_post(postId).status, ItemPostStatus.pendingHandover);
    expect(_post(postId).selectedRequesterId, 'u2');
    expect(_request(requestId).status, ItemRequestStatus.approved);
  });

  test('a handover completes only after both parties confirm', () async {
    final (postId, requestId) = await _postWithRequest('confirm');
    final auth = AuthController();
    final items = ItemController();
    await auth.login('nimal@example.com', 'x');
    await items.selectRequester(postId, requestId);
    final donationsBefore = _donations('u1');

    expect(await items.confirmHandover(postId), isNull);
    expect(items.exchangeFor(postId)!.isCompleted, isFalse);
    expect(_post(postId).status, ItemPostStatus.pendingHandover);

    await auth.login('kamani@example.com', 'x');
    expect(await items.confirmHandover(postId), isNull);
    expect(items.exchangeFor(postId)!.isCompleted, isTrue);
    expect(_post(postId).status, ItemPostStatus.completed);
    expect(_donations('u1'), donationsBefore + 1);
  });

  test('someone outside the exchange cannot confirm it', () async {
    final (postId, requestId) = await _postWithRequest('outsider');
    final auth = AuthController();
    final items = ItemController();
    await auth.login('nimal@example.com', 'x');
    await items.selectRequester(postId, requestId);

    await auth.login('sunil@example.com', 'x');
    expect(await items.confirmHandover(postId), isNotNull);
    expect(_post(postId).status, ItemPostStatus.pendingHandover);
  });

  test('cancelling puts the item back on offer', () async {
    final (postId, requestId) = await _postWithRequest('cancel');
    final auth = AuthController();
    final items = ItemController();
    await auth.login('nimal@example.com', 'x');
    await items.selectRequester(postId, requestId);

    expect(await items.cancelExchange(postId), isNull);
    expect(_post(postId).status, ItemPostStatus.active);
    expect(_post(postId).selectedRequesterId, isNull);
    expect(_request(requestId).status, ItemRequestStatus.rejected);
    expect(items.exchangeFor(postId), isNull);
    expect(await items.selectRequester(postId, requestId), isNotNull,
        reason: 'a declined request cannot be selected again');
  });

  test('a donor cannot select a second requester', () async {
    final (postId, requestId) = await _postWithRequest('second');
    MockDataService.instance.itemRequests.add(ItemRequestModel(
      id: 'req-second-b',
      requesterId: 'u4',
      requesterName: 'Priya Rajan',
      itemPostId: postId,
      description: 'Me too',
      reason: 'Studying',
      category: 'Electronics',
      district: 'Kandy',
      city: 'Peradeniya',
      createdAt: DateTime.now(),
    ));
    final auth = AuthController();
    final items = ItemController();
    await auth.login('nimal@example.com', 'x');
    await items.selectRequester(postId, requestId);

    expect(await items.selectRequester(postId, 'req-second-b'), isNotNull);
    await RequestController().loadRequests();
    expect(_request('req-second-b').status, ItemRequestStatus.pending);
  });

  testWidgets('splash goes straight home when a session is restored',
      (tester) async {
    final auth = AuthController();
    await tester.runAsync(() => auth.login('nimal@example.com', 'x'));

    String? route;
    SplashController().resolveNextRoute(auth).then((value) => route = value);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump(SplashController.minimumDisplayDuration);

    expect(auth.currentUser?.id, 'u1');
    expect(route, AppRoutes.home);
  });

  test('password reset with an emailed code works on mock data', () async {
    final auth = AuthController();
    expect(
      await auth.resetPassword(
        email: 'nimal@example.com',
        code: '000000',
        newPassword: 'newpass1',
      ),
      isFalse,
    );
    expect(auth.errorMessage, "That code isn't right.");
    expect(
      await auth.resetPassword(
        email: 'nimal@example.com',
        code: '123456',
        newPassword: 'newpass1',
      ),
      isTrue,
    );
  });
}
