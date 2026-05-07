import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/utils/json_utils.dart';
import 'package:qadaya_lawyersys/features/workqueue/models/workqueue_task.dart';

class WorkqueueRepository {

  WorkqueueRepository(this.apiClient);
  final ApiClient apiClient;

  Future<List<WorkqueueTask>> getMyTasks({String? status}) async {
    final queryParameters = <String, dynamic>{
      'assignedToMe': true,
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final response =
        await apiClient.get('/tasks', queryParameters: queryParameters);
    final items = normalizeJsonList(response.data);
    return items
        .whereType<Map<String, dynamic>>()
        .map(WorkqueueTask.fromJson)
        .toList();
  }

  Future<void> updateTaskStatus(int id, String status) async {
    await apiClient.put('/tasks/$id', data: {'status': status});
  }

  Future<void> completeTask(int id) async {
    await apiClient.put('/tasks/$id/complete');
  }

  Future<void> reassignTask(int id, int newEmployeeId) async {
    await apiClient.put('/tasks/$id', data: {'assignedToId': newEmployeeId});
  }

  Future<List<WorkqueueTask>> getTasksByEmployee(int userId) async {
    final response = await apiClient.get('/tasks', queryParameters: {
      'assignedToId': userId,
      'pageSize': 20,
    },);
    final items = normalizeJsonList(response.data);
    return items.whereType<Map<String, dynamic>>().map(WorkqueueTask.fromJson).toList();
  }
}
