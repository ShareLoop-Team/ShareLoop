import '../models/exchange_model.dart';
import 'mock/mock_exchange_repository.dart';

/// Repository: the handover workflow between a donor and the requester they
/// select, over in-memory data.
abstract class ExchangeRepository {
  factory ExchangeRepository() => MockExchangeRepository();

  /// The donor picks [requestId]; the post becomes pending handover and the
  /// two parties can see each other's contact details.
  Future<ExchangeModel> selectRequester({
    required String postId,
    required String requestId,
  });

  /// The signed-in party confirms the handover happened. Completes the
  /// exchange once both parties have confirmed.
  Future<ExchangeModel> confirmHandover(String postId);

  /// Either party backs out before completion; the post goes back on offer.
  Future<ExchangeModel> cancelExchange(String postId);

  /// The live (not cancelled) exchange for a post, if the caller is part of it.
  Future<ExchangeModel?> getExchangeForPost(String postId);

  /// Exchanges where [userId] is the donor or requester, newest first.
  Future<List<ExchangeModel>> getExchangesByUser(String userId);
}
