import '../../core/api/api_client.dart';
import '../models/task.dart';

class TasksRepository {
  final ApiClient apiClient;

  TasksRepository(this.apiClient);

  Future<List<Task>> getTasks({int page = 1, int pageSize = 10, String? search}) async {
    final queryParameters = {
      'page': page,
      'pageSize': pageSize,
      if (search != null) 'search': search,
    };
    
    final response = await apiClient.get('/AdminTasks', queryParameters: queryParameters);
    
    // Based on the ClientApp API response structure
    final tasksData = response.data?.items ?? response.data ?? [];
    
    if (tasksData is List) {
      return tasksData.map((json) => Task.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  Future<List<Task>> searchTasks(String query) async {
    final response = await apiClient.get('/AdminTasks', queryParameters: {
      'page': 1,
      'pageSize': 100, // Get more items for search
      'search': query,
    });
    
    final tasksData = response.data?.items ?? response.data ?? [];
    
    if (tasksData is List) {
      return tasksData.map((json) => Task.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  Future<Task> addTask(Task task) async {
    final response = await apiClient.post('/AdminTasks', data: task.toJson());
    return Task.fromJson(response.data);
  }

  Future<Task> updateTask(Task task) async {
    if (task.id == null) {
      throw Exception('Task ID is required for update');
    }
    final response = await apiClient.put('/AdminTasks/${task.id}', data: task.toJson());
    return Task.fromJson(response.data);
  }

  Future<void> deleteTask(int taskId) async {
    await apiClient.delete('/AdminTasks/$taskId');
  }
}