import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/utils/json_utils.dart';
import 'package:qadaya_lawyersys/features/auditlogs/models/audit_log.dart';

class AuditLogsRepository {

  AuditLogsRepository(this.apiClient);
  final ApiClient apiClient;

  Future<List<AuditLog>> getLogs({
    String? search,
    String? entityName,
    String? action,
    int page = 1,
    int pageSize = 30,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
      if (entityName != null && entityName.isNotEmpty) 'entityName': entityName,
      if (action != null && action.isNotEmpty) 'action': action,
    };

    final response = await apiClient.get(
      '/auditlogs',
      queryParameters: queryParameters,
    );

    final raw = normalizeJsonList(response.data);
    return raw
        .whereType<Map>()
        .map((e) => AuditLog.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
