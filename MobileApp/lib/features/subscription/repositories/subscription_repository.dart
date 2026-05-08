import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/utils/json_utils.dart';
import 'package:qadaya_lawyersys/features/subscription/models/subscription_package.dart';
import 'package:qadaya_lawyersys/features/subscription/models/tenant_subscription.dart';

class SubscriptionRepository {

  SubscriptionRepository(this.apiClient);
  final ApiClient apiClient;

  Future<List<SubscriptionPackage>> getPublicPackages() async {
    final response = await apiClient.get('/subscriptionpackages/public');
    final data = normalizeJsonList(response.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map(SubscriptionPackage.fromJson)
        .toList();
  }

  Future<TenantSubscription?> getCurrentSubscription() async {
    try {
      final response = await apiClient.get('/TenantSubscriptions/current');
      if (response.data is Map<String, dynamic>) {
        return TenantSubscription.fromJson(
            response.data as Map<String, dynamic>,);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
