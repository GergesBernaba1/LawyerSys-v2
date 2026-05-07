import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/api/api_constants.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/core/storage/local_database.dart';
import 'package:qadaya_lawyersys/features/documents/bloc/documents_bloc.dart';
import 'package:qadaya_lawyersys/features/documents/bloc/documents_event.dart';
import 'package:qadaya_lawyersys/features/documents/bloc/documents_state.dart';
import 'package:qadaya_lawyersys/features/documents/models/document.dart';
import 'package:qadaya_lawyersys/features/documents/repositories/documents_repository.dart';
import 'package:qadaya_lawyersys/features/documents/screens/document_viewer_screen.dart';
import 'package:qadaya_lawyersys/shared/widgets/skeleton_loader.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentsListScreen extends StatefulWidget {
  const DocumentsListScreen({super.key});

  @override
  State<DocumentsListScreen> createState() => _DocumentsListScreenState();
}

class _DocumentsListScreenState extends State<DocumentsListScreen> {
  late final DocumentsBloc _bloc;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _bloc = DocumentsBloc(
        documentsRepository:
            DocumentsRepository(ApiClient(), LocalDatabase.instance),);
    _bloc.add(LoadDocuments());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (_isNearBottom) {
      _bloc.add(LoadMoreDocuments());
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _showShareSheet(BuildContext context, String url) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                l10n.shareLink,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(url),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: l10n.copyLink,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.linkCopied)),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text(l10n.openInBrowser),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUploadSheet(BuildContext context) {
    // NOTE: file_picker package is not available in pubspec.yaml.
    // Using a manual file path TextField as a fallback.
    // To enable proper file picking, add `file_picker` to pubspec.yaml
    // and replace this TextField with FilePicker.platform.pickFiles().
    final filePathController = TextEditingController();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet<void>(
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
                SnackBar(
                    content: Text(l10n.documentUploadedSuccessfully),),
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
                      l10n.uploadDocument,
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // File path input (file_picker not available — manual path entry)
                    TextField(
                      controller: filePathController,
                      decoration: InputDecoration(
                        labelText: l10n.pleaseEnterFilePath,
                        hintText: '/storage/emulated/0/Documents/file.pdf',
                        helperText: l10n.pleaseEnterFilePath,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.folder_open),
                          onPressed: () {
                            // File picker not implemented - manual path entry required
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
                      decoration: InputDecoration(
                        labelText: l10n.description,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.description,
                        border: const OutlineInputBorder(),
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
                                      strokeWidth: 2, color: Colors.white,),
                                )
                              : const Icon(Icons.upload),
                          label: Text(isUploading
                              ? l10n.uploadDocument
                              : l10n.uploadDocument,),
                          onPressed: isUploading
                              ? null
                              : () {
                                  final path =
                                      filePathController.text.trim();
                                  if (path.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              l10n.pleaseEnterFilePath,),),
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
                                  ),);
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

  void _showRenameDialog(BuildContext context, Document doc) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: doc.fileName);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.renameDocument),
        content: TextFormField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.rename,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                _bloc.add(RenameDocument(
                  documentId: doc.id,
                  newName: newName,
                ),);
              }
              Navigator.pop(dialogCtx);
            },
            child: Text(l10n.rename),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.documents),
          actions: [
            Semantics(
              label: 'Refresh documents',
              hint: 'Tap to reload the documents list',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _bloc.add(RefreshDocuments()),
              ),
            ),
          ],
        ),
        floatingActionButton: Semantics(
          label: 'Upload document',
          hint: 'Tap to upload a new document',
          button: true,
          child: FloatingActionButton(
            tooltip: l10n.uploadDocument,
            onPressed: () => _showUploadSheet(context),
            child: const Icon(Icons.upload_file),
          ),
        ),
        body: BlocConsumer<DocumentsBloc, DocumentsState>(
          listener: (context, state) {
            if (state is DocumentsUploadSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(l10n.documentUploadedSuccessfully),),
              );
            } else if (state is DocumentsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.error}')),
              );
            } else if (state is DocumentShareLinkLoaded) {
              _showShareSheet(context, state.url);
            } else if (state is DocumentRenamed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.renamedSuccessfully)),
              );
            }
          },
          builder: (context, state) {
            if (state is DocumentsLoading || state is DocumentsUploading) {
              return const ListSkeleton(itemCount: 6);
            }
            if (state is DocumentsError) {
              return Center(child: Text('Error: ${state.error}'));
            }
            if (state is DocumentsLoaded) {
              final docs = state.documents;
              if (docs.isEmpty) {
                return Center(child: Text(l10n.noDocumentsFound));
              }
              return ListView.builder(
                controller: _scrollController,
                itemCount: docs.length + (state.hasMore || state.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= docs.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final document = docs[index];
                  return ListTile(
                    leading: Icon(document.isPdf
                        ? Icons.picture_as_pdf
                        : Icons.insert_drive_file,),
                    title: Text(document.code.isNotEmpty
                        ? document.code
                        : document.fileName,),
                    subtitle: Text(document.fileName),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share),
                          tooltip: l10n.shareDocument,
                          onPressed: () => _bloc.add(ShareDocument(document.id)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => _bloc.add(DownloadDocument(document)),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'rename') {
                              _showRenameDialog(context, document);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'rename',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, size: 18),
                                  const SizedBox(width: 8),
                                  Text(l10n.rename),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () async {
                      if (document.isPdf || document.isImage) {
                        final downloaded = await _downloadOrReuse(document);
                        if (downloaded != null && context.mounted) {
                          unawaited(
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => DocumentViewerScreen(
                                  documentFile: downloaded,
                                  document: document,
                                ),
                              ),
                            ),
                          );
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
    if (localFile.existsSync()) {
      return localFile;
    }

    try {
      final dio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {'Content-Type': 'application/octet-stream'},),);
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
