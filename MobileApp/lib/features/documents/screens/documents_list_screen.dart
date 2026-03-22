import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../bloc/documents_bloc.dart';
import '../bloc/documents_event.dart';
import '../bloc/documents_state.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/storage/local_database.dart';
import '../models/document.dart';
import '../repositories/documents_repository.dart';
import 'document_viewer_screen.dart';

class DocumentsListScreen extends StatefulWidget {
  const DocumentsListScreen({super.key});

  @override
  State<DocumentsListScreen> createState() => _DocumentsListScreenState();
}

class _DocumentsListScreenState extends State<DocumentsListScreen> {
  late final DocumentsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = DocumentsBloc(documentsRepository: DocumentsRepository(ApiClient(), LocalDatabase.instance));
    _bloc.add(LoadDocuments());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Documents'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _bloc.add(RefreshDocuments()),
            )
          ],
        ),
        body: BlocBuilder<DocumentsBloc, DocumentsState>(
          builder: (context, state) {
            if (state is DocumentsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DocumentsError) {
              return Center(child: Text('Error: ${state.error}'));
            }
            if (state is DocumentsLoaded) {
              final docs = state.documents;
              if (docs.isEmpty) {
                return const Center(child: Text('No documents found'));
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final document = docs[index];
                  return ListTile(
                    leading: Icon(document.isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file),
                    title: Text(document.code.isNotEmpty ? document.code : document.fileName),
                    subtitle: Text(document.fileName),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _bloc.add(DownloadDocument(document)),
                    ),
                    onTap: () async {
                      if (document.isPdf || document.isImage) {
                        final downloaded = await _downloadOrReuse(document);
                        if (downloaded != null) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentViewerScreen(documentFile: downloaded, document: document)));
                        }
                      } else {
                        final url = '${ApiConstants.baseUrl}/api/files/${document.id}/download';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        }
                      }
                    },
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Future<File?> _downloadOrReuse(Document document) async {
    final directory = await getApplicationDocumentsDirectory();
    final localFile = File('${directory.path}/${document.fileName}');
    if (await localFile.exists()) {
      return localFile;
    }

    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl, headers: {'Content-Type': 'application/octet-stream'}));
      final response = await dio.get<List<int>>(
        '/api/files/${document.id}/download',
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to fetch remote file');
      }
      final bytes = response.data!;
      await localFile.writeAsBytes(bytes, flush: true);
      return localFile;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      return null;
    }
  }
}
