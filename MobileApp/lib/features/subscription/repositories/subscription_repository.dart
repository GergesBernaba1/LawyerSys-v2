import '../../../core/api/api_client.dart';
import '../../../core/utils/json_utils.dart';
import '../models/subscription_package.dart';

class SubscriptionRepository {
  final ApiClient apiClient;

  SubscriptionRepository(this.apiClient);

  Future<List<SubscriptionPackage>> getPublicPackages() async {
    final response = await apiClient.get('/subscriptionpackages/public');
    final data = normalizeJsonList(response.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map(SubscriptionPackage.fromJson)
        .toList();
  }
}
