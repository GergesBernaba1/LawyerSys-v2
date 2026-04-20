import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/storage/local_database.dart';
import '../../../core/utils/json_utils.dart';
import '../models/document.dart';

class DocumentsRepository {
  final ApiClient apiClient;
  final LocalDatabase localDatabase;

  DocumentsRepository(this.apiClient, this.localDatabase);

  Future<List<Document>> getDocuments({String? search}) async {
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    final response = await apiClient.get('/api/files', queryParameters: params);
    final data = normalizeJsonList(response.data);

    if (data.isEmpty) {
      return [];
    }

    final docs =
        data.whereType<Map<String, dynamic>>().map(Document.fromJson).toList();

    // Cache locally for offline access
    for (final doc in docs) {
      await localDatabase.upsertDocument(doc.id.toString(), doc.toJson(),
          tenantId: null, isDownloaded: false);
    }

    return docs;
  }

  Future<File> downloadDocument(Document document) async {
    final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
    final response = await dio.get<List<int>>(
      '/files/${document.id}/download',
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.statusCode != 200 || response.data == null) {
      throw Exception('Failed to download document: ${document.code}');
    }

    final bytes = response.data!;
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${document.fileName}');

    await file.writeAsBytes(bytes, flush: true);
    await localDatabase.upsertDocument(
        document.id.toString(), document.toJson(),
        tenantId: null, isDownloaded: true);
    return file;
  }

  Future<List<Document>> getCachedDocuments(
      {String? tenantId, int limit = 100}) async {
    final rows =
        await localDatabase.getDocuments(tenantId: tenantId, limit: limit);
    return rows.map((row) {
      final json =
          Map<String, dynamic>.from(row['data'] as Map<String, dynamic>);
      return Document.fromJson(json);
    }).toList();
  }

  Future<void> uploadDocument(
    String filePath, {
    String? title,
    String? description,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
      if (title != null) 'title': title,
      if (description != null) 'description': description,
    });
    await apiClient.post('/files/upload', data: formData);
  }

  Future<void> renameDocument(int id, String newName) async {
    await apiClient.patch('/files/$id', data: {'fileName': newName});
  }

  Future<String?> getShareLink(int documentId) async {
    try {
      final response = await apiClient.get('/files/$documentId/share-link');
      if (response.data is Map) {
        return (response.data as Map)['url']?.toString()
            ?? (response.data as Map)['shareLink']?.toString()
            ?? (response.data as Map)['link']?.toString();
      }
      return response.data?.toString();
    } catch (_) {
      return null;
    }
  }
}
