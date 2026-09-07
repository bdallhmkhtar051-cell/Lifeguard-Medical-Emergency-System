import '../../core/network/api_client.dart';

abstract interface class HealthRepository {
  Future<void> check();
}

class ApiHealthRepository implements HealthRepository {
  ApiHealthRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> check() => _apiClient.checkHealth();
}
