import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/client_portal_bloc.dart';
import '../bloc/client_portal_event.dart';
import '../bloc/client_portal_state.dart';

class PortalDocumentsScreen extends StatefulWidget {
  const PortalDocumentsScreen({super.key});

  @override
  State<PortalDocumentsScreen> createState() => _PortalDocumentsScreenState();
}

class _PortalDocumentsScreenState extends State<PortalDocumentsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ClientPortalBloc>().add(LoadPortalDocuments());
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: cannot open URL')),
      );
    }
  }

  void _showUploadSheet(BuildContext context) {
    final filePathController = TextEditingController();
    final titleController = TextEditingController();
    final bloc = context.read<ClientPortalBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return BlocProvider.value(
          value: bloc,
          child: BlocListener<ClientPortalBloc, ClientPortalState>(
            listener: (ctx, state) {
              if (state is PortalDocumentUploaded) {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.documentUploaded)),
                );
              } else if (state is ClientPortalError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${AppLocalizations.of(context)!.error}: ${state.message}')),
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
                        AppLocalizations.of(ctx)!.uploadDocument,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      // TODO: replace with FilePicker
                      TextField(
                        controller: filePathController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(ctx)!.pleaseEnterFilePath,
                          hintText: '/storage/emulated/0/Documents/file.pdf',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(ctx)!.description,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      BlocBuilder<ClientPortalBloc, ClientPortalState>(
                        builder: (_, state) {
                          final isUploading = state is PortalDocumentUploading;
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
                                ? AppLocalizations.of(context)!.uploadDocument
                                : AppLocalizations.of(context)!.uploadDocument),
                            onPressed: isUploading
                                ? null
                                : () {
                                    final path = filePathController.text.trim();
                                    if (path.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(AppLocalizations.of(context)!.pleaseEnterFilePath)),
                                      );
                                      return;
                                    }
                                    ctx.read<ClientPortalBloc>().add(
                                          UploadPortalDocument(
                                            filePath: path,
                                            title: titleController.text.trim().isEmpty
                                                ? null
                                                : titleController.text.trim(),
                                          ),
                                        );
                                  },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    ).whenComplete(() {
      filePathController.dispose();
      titleController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.portalDocuments)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUploadSheet(context),
        child: const Icon(Icons.upload_file),
      ),
      body: BlocConsumer<ClientPortalBloc, ClientPortalState>(
        listener: (context, state) {
          if (state is ClientPortalError) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${l.error}: ${state.message}')));
          }
          if (state is PortalDocumentUrlReady) {
            _openUrl(state.url);
          }
        },
        builder: (context, state) {
          if (state is ClientPortalLoading || state is PortalDocumentUploading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ClientPortalError) {
            return Center(child: Text('${l.error}: ${state.message}'));
          }
          if (state is ClientPortalDocumentsLoaded) {
            final docs = state.documents;
            if (docs.isEmpty) {
              return Center(child: Text(l.noDataAvailable));
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<ClientPortalBloc>().add(RefreshPortalDocuments()),
              child: ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(doc.subject),
                    subtitle: Text(
                        '${doc.from} • ${doc.sentAt.toLocal().toIso8601String().split('T').first}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      tooltip: l.downloadStarted,
                      onPressed: () => context
                          .read<ClientPortalBloc>()
                          .add(DownloadPortalDocument(doc.messageId)),
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
