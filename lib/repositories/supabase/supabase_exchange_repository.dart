import '../../models/exchange_model.dart';
import '../../services/backend_service.dart';
import '../exchange_repository.dart';
import 'supabase_rows.dart';

/// [ExchangeRepository] backed by the workflow functions in
/// supabase/migrations (select_requester, confirm_handover,
/// cancel_exchange), which check the caller and every state change.
class SupabaseExchangeRepository implements ExchangeRepository {
  Future<ExchangeModel> _call(String function, Map<String, dynamic> params) {
    return BackendService.guard(() async {
      final row = await BackendService.client.rpc(function, params: params);
      return SupabaseRows.exchange(row as Map<String, dynamic>);
    });
  }

  @override
  Future<ExchangeModel> selectRequester({
    required String postId,
    required String requestId,
  }) =>
      _call('select_requester', {'p_request_id': requestId});

  @override
  Future<ExchangeModel> confirmHandover(String postId) =>
      _call('confirm_handover', {'p_item_id': postId});

  @override
  Future<ExchangeModel> cancelExchange(String postId) =>
      _call('cancel_exchange', {'p_item_id': postId});

  @override
  Future<ExchangeModel?> getExchangeForPost(String postId) {
    return BackendService.guard(() async {
      final row = await BackendService.client
          .from('exchanges')
          .select()
          .eq('item_id', postId)
          .neq('status', 'cancelled')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row == null ? null : SupabaseRows.exchange(row);
    });
  }
}
