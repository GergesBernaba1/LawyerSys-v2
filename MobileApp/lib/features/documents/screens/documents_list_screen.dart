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
    _bloc = DocumentsBloc(
        documentsRepository:
            DocumentsRepository(ApiClient(), LocalDatabase.instance));
    _bloc.add(LoadDocuments());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _showUploadSheet(BuildContext context) {
    // NOTE: file_picker package is not available in pubspec.yaml.
    // Using a manual file path TextField as a fallback.
    // To enable proper file picking, add `file_picker` to pubspec.yaml
    // and replace this TextField with FilePicker.platform.pickFiles().
    final filePathController = TextEditingController();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return BlocListener<DocumentsBloc, DocumentsState>(
          bloc: _bloc,
          listener: (ctx, state) {
            if (state is DocumentsUploadSuccess) {
              Navigator.pop(sheetCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Document uploaded successfully')), // TODO: localize
              );
            } else if (state is DocumentsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.error}')),
              );
            }
          },
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Upload Document', // TODO: localize
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // File path input (file_picker not available — manual path entry)
                    TextField(
                      controller: filePathController,
                      decoration: InputDecoration(
                        labelText: 'File Path', // TODO: localize
                        hintText: '/storage/emulated/0/Documents/file.pdf',
                        helperText:
                            'Enter the full path to your file', // TODO: localize
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.folder_open),
                          onPressed: () {
                            // TODO: replace with FilePicker when file_picker is added to pubspec.yaml
                            setSheetState(() {});
                          },
                        ),
                      ),
                      onChanged: (v) {
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title (optional)', // TODO: localize
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)', // TODO: localize
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    BlocBuilder<DocumentsBloc, DocumentsState>(
                      bloc: _bloc,
                      builder: (_, state) {
                        final isUploading = state is DocumentsUploading;
                        return ElevatedButton.icon(
                          icon: isUploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.upload),
                          label: Text(isUploading
                              ? 'Uploading...' // TODO: localize
                              : 'Upload'), // TODO: localize
                          onPressed: isUploading
                              ? null
                              : () {
                                  final path =
                                      filePathController.text.trim();
                                  if (path.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Please enter a file path')), // TODO: localize
                                    );
                                    return;
                                  }
                                  _bloc.add(UploadDocument(
                                    path,
                                    title: titleController.text.trim().isEmpty
                                        ? null
                                        : titleController.text.trim(),
                                    description: descriptionController.text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : descriptionController.text.trim(),
                                  ));
                                },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      filePathController.dispose();
      titleController.dispose();
      descriptionController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Documents'), // TODO: localize
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _bloc.add(RefreshDocuments()),
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Upload Document', // TODO: localize
          onPressed: () => _showUploadSheet(context),
          child: const Icon(Icons.upload_file),
        ),
        body: BlocConsumer<DocumentsBloc, DocumentsState>(
          listener: (context, state) {
            if (state is DocumentsUploadSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Document uploaded successfully')), // TODO: localize
              );
            } else if (state is DocumentsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.error}')),
              );
            }
          },
          builder: (context, state) {
            if (state is DocumentsLoading || state is DocumentsUploading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DocumentsError) {
              return Center(child: Text('Error: ${state.error}'));
            }
            if (state is DocumentsLoaded) {
              final docs = state.documents;
              if (docs.isEmpty) {
                return const Center(child: Text('No documents found')); // TODO: localize
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final document = docs[index];
                  return ListTile(
                    leading: Icon(document.isPdf
                        ? Icons.picture_as_pdf
                        : Icons.insert_drive_file),
                    title: Text(document.code.isNotEmpty
                        ? document.code
                        : document.fileName),
                    subtitle: Text(document.fileName),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _bloc.add(DownloadDocument(document)),
                    ),
                    onTap: () async {
                      if (document.isPdf || document.isImage) {
                        final downloaded = await _downloadOrReuse(document);
                        if (downloaded != null && context.mounted) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => DocumentViewerScreen(
                                      documentFile: downloaded,
                                      document: document)));
                        }
                      } else {
                        final url =
                            '${ApiConstants.apiRoot}/api/files/${document.id}/download';
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
      final dio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {'Content-Type': 'application/octet-stream'}));
      final response = await dio.get<List<int>>(
        '/files/${document.id}/download',
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to fetch remote file');
      }
      final bytes = response.data!;
      await localFile.writeAsBytes(bytes, flush: true);
      return localFile;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
      return null;
    }
  }
}
