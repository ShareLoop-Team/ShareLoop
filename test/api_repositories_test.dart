import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shareloop/core/errors/app_exception.dart';
import 'package:shareloop/models/email_code.dart';
import 'package:shareloop/models/item_post_model.dart';
import 'package:shareloop/models/item_request_model.dart';
import 'package:shareloop/models/rating_review_model.dart';
import 'package:shareloop/repositories/api/api_exchange_repository.dart';
import 'package:shareloop/repositories/api/api_item_post_repository.dart';
import 'package:shareloop/repositories/api/api_item_request_repository.dart';
import 'package:shareloop/repositories/api/api_rating_repository.dart';
import 'package:shareloop/repositories/api/api_user_repository.dart';
import 'package:shareloop/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The API repositories against a fake Laravel server: request shapes,
/// JSON mapping, token handling and error messages.
void main() {
  late List<http.BaseRequest> sent;

  Map<String, dynamic> userJson({String? email = 'nimal@example.com'}) => {
        'id': 'u1',
        'display_name': 'Nimal',
        'email': email,
        'phone': email == null ? null : '0771234567',
        'district': 'Colombo',
        'city': 'Dehiwala',
        'donation_count': 3,
        'rating_avg': 4.5,
        'rating_count': 2,
        'is_admin': false,
        'status': 'active',
      };

  final itemJson = {
    'id': 'i1',
    'donor_id': 'u1',
    'donor': {'display_name': 'Nimal', 'donation_count': 3},
    'title': 'School bag',
    'description': 'Blue',
    'condition': 'Good',
    'category': 'School Supplies',
    'district': 'Kandy',
    'city': '',
    'image_paths': ['item-images/u1/a.jpg'],
    'image_urls': ['http://localhost:8000/api/photos/item-images/u1/a.jpg?signature=x'],
    'status': 'pending_handover',
    'selected_requester_id': 'u2',
    'created_at': '2026-10-28T10:00:00+00:00',
  };

  void serve(http.Response Function(http.Request request) handler) {
    ApiClient.instance.httpClient = MockClient((request) async {
      sent.add(request);
      return handler(request);
    });
  }

  http.Response json(Object body, [int status = 200]) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );

  setUp(() async {
    sent = [];
    SharedPreferences.setMockInitialValues({});
    await ApiClient.instance.initialize();
  });

  test('login stores the token and sends it afterwards', () async {
    serve((request) => request.url.path.endsWith('/auth/login')
        ? json({'token': '1|abc', 'user': userJson()})
        : json({'data': userJson()}));
    final repository = ApiUserRepository();

    final user = await repository.login('nimal@example.com', 'secret123');
    expect(user!.name, 'Nimal');
    expect(user.averageRating, 4.5);
    expect(jsonDecode((sent.first as http.Request).body)['email'],
        'nimal@example.com');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('shareloop.api_token'), '1|abc');

    await repository.getCurrentUser();
    expect(sent.last.headers['Authorization'], 'Bearer 1|abc');
  });

  test('validation errors surface the first message', () async {
    serve((_) => json({
          'message': 'The email has already been taken.',
          'errors': {
            'email': ['An account already exists for that email. Please sign in.'],
          },
        }, 422));

    expect(
      () => ApiUserRepository().register(
        name: 'N',
        email: 'n@example.com',
        password: 'secret123',
        phone: '0771234567',
        district: 'Colombo',
        city: '',
        code: '123456',
      ),
      throwsA(isA<AppException>().having((e) => e.message, 'message',
          'An account already exists for that email. Please sign in.')),
    );
  });

  test('an expired token is dropped and the user starts signed out', () async {
    await ApiClient.instance.saveToken('old');
    serve((_) => json({'message': 'Your session has expired. Please sign in again.'}, 401));

    expect(await ApiUserRepository().getCurrentUser(), isNull);
    expect(ApiClient.instance.hasToken, isFalse);
  });

  test('email codes: request, sign in with a code, reset password', () async {
    serve((request) {
      final path = request.url.path;
      if (path.endsWith('/auth/code')) {
        return json({'message': 'sent', 'resend_in': 45, 'debug_code': '654321'});
      }
      if (path.endsWith('/auth/login-with-code')) {
        return json({'token': '2|xyz', 'user': userJson()});
      }
      return json({'message': 'Your password has been changed.'});
    });
    final repository = ApiUserRepository();

    final ticket =
        await repository.requestEmailCode('n@example.com', EmailCodePurpose.login);
    expect(jsonDecode((sent.last as http.Request).body),
        {'email': 'n@example.com', 'purpose': 'login'});
    expect(ticket.resendInSeconds, 45);
    expect(ticket.debugCode, '654321');

    final user = await repository.loginWithCode('n@example.com', '654321');
    expect(user.name, 'Nimal');
    expect(ApiClient.instance.hasToken, isTrue);

    await repository.resetPassword(
      email: 'n@example.com',
      code: '111111',
      newPassword: 'newpass1',
    );
    expect(sent.last.url.path, endsWith('/auth/reset-password'));
    expect(jsonDecode((sent.last as http.Request).body)['password'], 'newpass1');
  });

  test('a registration code request carries the form for checking', () async {
    serve((_) => json({'message': 'sent'}));
    await ApiUserRepository().requestEmailCode(
      'new@example.com',
      EmailCodePurpose.register,
      registration: const PendingRegistration(
        name: 'New',
        email: 'new@example.com',
        password: 'secret123',
        phone: '0771234567',
        district: 'Kandy',
        city: '',
      ),
    );
    final body = jsonDecode((sent.single as http.Request).body);
    expect(body['purpose'], 'register');
    expect(body['phone'], '0771234567');
    expect(body.containsKey('debug_code'), isFalse);
  });

  test('hidden contact details map to empty strings', () async {
    serve((_) => json({'data': userJson(email: null)}));
    final user = await ApiUserRepository().getUserById('u1');
    expect(user!.email, '');
    expect(user.phone, '');
  });

  test('posts map photos, donor and status', () async {
    serve((_) => json({'data': [itemJson]}));
    final posts = await ApiItemPostRepository().getAllPosts(limit: 10, offset: 20);

    expect(sent.single.url.queryParameters, {'limit': '10', 'offset': '20'});
    final post = posts.single;
    expect(post.donorName, 'Nimal');
    expect(post.donorDonationCount, 3);
    expect(post.status, ItemPostStatus.pendingHandover);
    expect(post.selectedRequesterId, 'u2');
    expect(post.photoUrls.single, contains('signature='));
  });

  test('a missing post is null rather than an error', () async {
    serve((_) => json({'message': 'Item not found.'}, 404));
    expect(await ApiItemPostRepository().getPostById('nope'), isNull);
  });

  test('requests filter by post and map the requester', () async {
    serve((_) => json({
          'data': [
            {
              'id': 'r1',
              'requester_id': 'u2',
              'requester': {'display_name': 'Kavya'},
              'item_id': 'i1',
              'item_name': '',
              'description': 'Please',
              'reason': 'School',
              'notes': '',
              'category': 'School Supplies',
              'district': 'Kandy',
              'city': '',
              'status': 'approved',
              'created_at': '2026-10-28T10:00:00+00:00',
            },
          ],
        }));
    final requests = await ApiItemRequestRepository().getRequestsForPost('i1');

    expect(sent.single.url.queryParameters, {'item_id': 'i1'});
    expect(requests.single.requesterName, 'Kavya');
    expect(requests.single.status, ItemRequestStatus.approved);
  });

  test('exchange endpoints and a missing exchange', () async {
    serve((request) => request.url.path.endsWith('/exchange')
        ? json({'data': null})
        : json({
            'data': {
              'id': 'x1',
              'item_id': 'i1',
              'request_id': 'r1',
              'donor_id': 'u1',
              'requester_id': 'u2',
              'status': 'pending',
              'donor_confirmed_at': '2026-10-28T10:00:00+00:00',
              'requester_confirmed_at': null,
            },
          }, 201));
    final repository = ApiExchangeRepository();

    final exchange =
        await repository.selectRequester(postId: 'i1', requestId: 'r1');
    expect(sent.last.url.path, endsWith('/requests/r1/select'));
    expect(exchange.hasConfirmed('u1'), isTrue);
    expect(exchange.hasConfirmed('u2'), isFalse);
    expect(await repository.getExchangeForPost('i1'), isNull);
  });

  test('server errors are not shown raw', () async {
    serve((_) => json({'message': 'SQLSTATE[HY000] something broke'}, 500));
    expect(
      () => ApiRatingRepository().addRating(RatingReviewModel(
        id: '',
        itemPostId: 'i1',
        raterId: 'u1',
        rateeId: 'u2',
        stars: 5,
        comment: '',
        createdAt: DateTime.now(),
      )),
      throwsA(isA<AppException>().having(
          (e) => e.message, 'message', 'Something went wrong. Please try again.')),
    );
  });

  test('no connection gives a friendly message', () async {
    ApiClient.instance.httpClient =
        MockClient((_) async => throw http.ClientException('offline'));
    expect(
      () => ApiItemPostRepository().getAllPosts(),
      throwsA(isA<AppException>().having((e) => e.message, 'message',
          'Could not reach ShareLoop. Check your connection and try again.')),
    );
  });
}
