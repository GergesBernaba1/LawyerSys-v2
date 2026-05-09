import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/utils/json_utils.dart';
import 'package:qadaya_lawyersys/features/workqueue/models/workqueue_task.dart';

class WorkqueueRepository {

  WorkqueueRepository(this.apiClient);
  final ApiClient apiClient;

  // Backend route: GET /api/admintasks
  // The server auto-filters by current employee when the caller is an employee.
  Future<List<WorkqueueTask>> getMyTasks({String? status}) async {
    final response = await apiClient.get('/api/admintasks');
    final items = normalizeJsonList(response.data);
    final tasks = items
        .whereType<Map<String, dynamic>>()
        .map(WorkqueueTask.fromJson)
        .toList();
    // Client-side status filter (backend has no status field — type is used as proxy).
    if (status != null && status.isNotEmpty) {
      return tasks.where((t) => t.status == status).toList();
    }
    return tasks;
  }

  Future<void> updateTaskStatus(int id, String status) async {
    // Backend uses 'type' as the status-proxy field.
    await apiClient.put('/api/admintasks/$id', data: {'type': status});
  }

  Future<void> completeTask(int id) async {
    await apiClient.put('/api/admintasks/$id', data: {'type': 'Completed'});
  }

  Future<void> reassignTask(int id, int newEmployeeId) async {
    await apiClient.put('/api/admintasks/$id', data: {'employeeId': newEmployeeId});
  }

  Future<List<WorkqueueTask>> getTasksByEmployee(int userId) async {
    final response =
        await apiClient.get('/api/admintasks/byemployee/$userId');
    final items = normalizeJsonList(response.data);
    return items.whereType<Map<String, dynamic>>().map(WorkqueueTask.fromJson).toList();
  }
}
