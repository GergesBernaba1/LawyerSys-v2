import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/features/tasks/models/task.dart';

class TasksRepository {

  TasksRepository(this.apiClient);
  final ApiClient apiClient;

  List<Task> _parseTasks(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((json) => Task.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final items = data['items'] ?? data['Items'];
      if (items is List) {
        return items
            .whereType<Map>()
            .map((json) => Task.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
    }

    return const [];
  }

  Future<List<Task>> getTasks(
      {int page = 1, int pageSize = 10, String? search,}) async {
    final queryParameters = {
      'page': page,
      'pageSize': pageSize,
      if (search != null) 'search': search,
    };

    final response =
        await apiClient.get('/AdminTasks', queryParameters: queryParameters);
    return _parseTasks(response.data);
  }

  Future<List<Task>> searchTasks(String query) async {
    final response = await apiClient.get('/AdminTasks', queryParameters: {
      'page': 1,
      'pageSize': 100, // Get more items for search
      'search': query,
    },);

    return _parseTasks(response.data);
  }

  Map<String, dynamic> _toCreatePayload(Task task) {
    return {
      'taskName': task.taskName,
      'type': task.type,
      // Backend CreateAdminTaskDto requires non-null task date fields.
      'taskDate': task.taskDate ?? DateTime.now().toIso8601String(),
      'taskReminderDate':
          task.taskReminderDate ?? task.taskDate ?? DateTime.now().toIso8601String(),
      'notes': task.notes,
      'employeeId': task.employeeId,
    };
  }

  Map<String, dynamic> _toUpdatePayload(Task task) {
    return {
      'taskName': task.taskName,
      'type': task.type,
      'taskDate': task.taskDate,
      'taskReminderDate': task.taskReminderDate,
      'notes': task.notes,
      'employeeId': task.employeeId,
    };
  }

  Future<Task> addTask(Task task) async {
    final response = await apiClient.post('/AdminTasks', data: _toCreatePayload(task));
    return Task.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Task> updateTask(Task task) async {
    if (task.id == null) {
      throw Exception('Task ID is required for update');
    }
    final response =
        await apiClient.put('/AdminTasks/${task.id}', data: _toUpdatePayload(task));
    return Task.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteTask(int taskId) async {
    await apiClient.delete('/AdminTasks/$taskId');
  }
}
