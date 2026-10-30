import '../../models/exchange_model.dart';
import '../../services/api_client.dart';
import '../exchange_repository.dart';
import 'api_rows.dart';

/// [ExchangeRepository] backed by the Laravel API's workflow endpoints
/// (App\Services\ExchangeService checks the caller and every step).
class ApiExchangeRepository implements ExchangeRepository {
  ApiClient get _api => ApiClient.instance;

  @override
  Future<ExchangeModel> selectRequester({
    required String postId,
    required String requestId,
  }) async {
    final body = await _api.post('/requests/$requestId/select');
    return ApiRows.exchange(ApiRows.object(body));
  }

  @override
  Future<ExchangeModel> confirmHandover(String postId) async {
    final body = await _api.post('/items/$postId/confirm-handover');
    return ApiRows.exchange(ApiRows.object(body));
  }

  @override
  Future<ExchangeModel> cancelExchange(String postId) async {
    final body = await _api.post('/items/$postId/cancel-exchange');
    return ApiRows.exchange(ApiRows.object(body));
  }

  @override
  Future<ExchangeModel?> getExchangeForPost(String postId) async {
    final data = ApiRows.data(await _api.get('/items/$postId/exchange'));
    return data == null ? null : ApiRows.exchange(data as Map<String, dynamic>);
  }

  @override
  Future<List<ExchangeModel>> getExchangesByUser(String userId) async {
    final body = await _api.get('/me/exchanges');
    return [for (final row in ApiRows.list(body)) ApiRows.exchange(row)];
  }
}
