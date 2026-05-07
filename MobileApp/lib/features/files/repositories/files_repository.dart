import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/api/api_constants.dart';
import 'package:qadaya_lawyersys/core/utils/json_utils.dart';
import 'package:qadaya_lawyersys/features/files/models/file_model.dart';

class FilesRepository {

  FilesRepository(this.apiClient);
  final ApiClient apiClient;

  Future<List<FileModel>> getFiles({
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await apiClient.get(
      '/files',
      queryParameters: queryParams,
    );

    final data = normalizeJsonList(response.data);
    if (data.isEmpty) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) => FileModel.fromJson(Map<String, dynamic>.from(raw)))
        .toList();
  }

  Future<FileModel> getFileById(String id) async {
    final response = await apiClient.get('/files/$id');
    return FileModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<FileModel> createFile(Map<String, dynamic> data) async {
    final response = await apiClient.post('/files', data: data);
    return FileModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<FileModel> updateFile(String id, Map<String, dynamic> data) async {
    final response = await apiClient.put('/files/$id', data: data);
    return FileModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteFile(String id) async {
    await apiClient.delete('/files/$id');
  }

  /// Returns the download URL for a file.
  /// Tries to extract a URL from the API response; falls back to the endpoint URL.
  Future<String> getDownloadUrl(String id) async {
    try {
      final response = await apiClient.get('/files/$id/download');
      final data = response.data;
      if (data is Map) {
        final url = data['url'] ?? data['downloadUrl'] ?? data['link'];
        if (url != null && url.toString().isNotEmpty) {
          return url.toString();
        }
      }
      if (data is String && data.isNotEmpty) {
        return data;
      }
    } catch (_) {
      // fall through to constructed URL
    }
    // Fallback: build the URL from the known API root
    return '${ApiConstants.apiRoot}/api/files/$id/download';
  }
}
