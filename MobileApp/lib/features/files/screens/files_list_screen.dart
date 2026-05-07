import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/files_bloc.dart';
import '../bloc/files_event.dart';
import '../bloc/files_state.dart';
import '../models/file_model.dart';

class FilesListScreen extends StatefulWidget {
  const FilesListScreen({super.key});

  @override
  State<FilesListScreen> createState() => _FilesListScreenState();
}

class _FilesListScreenState extends State<FilesListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<FilesBloc>().add(LoadFiles());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  IconData _iconForExtension(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _subtitle(FileModel file) {
    final parts = <String>[];
    if (file.category != null && file.category!.isNotEmpty) {
      parts.add(file.category!);
    }
    if (file.formattedSize.isNotEmpty) parts.add(file.formattedSize);
    parts.add(
      '${file.createdAt.year}-'
      '${file.createdAt.month.toString().padLeft(2, '0')}-'
      '${file.createdAt.day.toString().padLeft(2, '0')}',
    );
    return parts.join(' · ');
  }

  Future<void> _openDownloadUrl(BuildContext context, String fileId) async {
    try {
      final repo = context.read<FilesBloc>().filesRepository;
      final url = await repo.getDownloadUrl(fileId);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenUrl)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.downloadFailed}: $e')),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final categoryController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.add),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: l10n.description),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.allFieldsAreRequired : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descController,
                  decoration: InputDecoration(labelText: l10n.description),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: categoryController,
                  decoration: InputDecoration(labelText: l10n.notes),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<FilesBloc>().add(CreateFile({
                  'title': titleController.text.trim(),
                  'description': descController.text.trim(),
                  'category': categoryController.text.trim(),
                }));
                Navigator.of(ctx).pop();
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(FileModel file) {
    final titleController = TextEditingController(text: file.title);
    final descController = TextEditingController(text: file.description ?? '');
    final categoryController = TextEditingController(text: file.category ?? '');
    final formKey = GlobalKey<FormState>();

    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.edit),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: l10n.description),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.allFieldsAreRequired : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descController,
                  decoration: InputDecoration(labelText: l10n.description),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: categoryController,
                  decoration: InputDecoration(labelText: l10n.notes),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<FilesBloc>().add(UpdateFile(file.id, {
                  'title': titleController.text.trim(),
                  'description': descController.text.trim(),
                  'category': categoryController.text.trim(),
                }));
                Navigator.of(ctx).pop();
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(FileModel file) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text('${l10n.delete} "${file.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<FilesBloc>().add(DeleteFile(file.id));
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FilesBloc, FilesState>(
      listener: (context, state) {
        if (state is FileOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is FilesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.documents),
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.search,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => context
                          .read<FilesBloc>()
                          .add(SearchFiles(_searchController.text)),
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (v) =>
                      context.read<FilesBloc>().add(SearchFiles(v)),
                ),
              ),

              // Body area
              Expanded(
                child: _buildBody(context, state),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showCreateDialog,
            tooltip: AppLocalizations.of(context)!.add,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, FilesState state) {
    if (state is FilesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is FilesError) {
      return Center(
        child: Text('${AppLocalizations.of(context)!.error}: ${state.message}'),
      );
    }

    if (state is FilesLoaded) {
      return _buildList(context, state.files);
    }

    // FilesInitial or FileOperationSuccess transitioning back to FilesLoaded
    // Show a spinner for the intermediate success state
    if (state is FileOperationSuccess) {
      return const Center(child: CircularProgressIndicator());
    }

    return const SizedBox.shrink();
  }

  Widget _buildList(BuildContext context, List<FileModel> files) {
    if (files.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noDocumentsFound),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<FilesBloc>().add(RefreshFiles());
        // Wait a short tick so the bloc has time to emit a new state
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return _buildFileTile(context, file);
        },
      ),
    );
  }

  Widget _buildFileTile(BuildContext context, FileModel file) {
    final ext = file.normalizedExtension;
    final iconColor = Theme.of(context).colorScheme.primary;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.15),
        child: Icon(_iconForExtension(ext), color: iconColor),
      ),
      title: Text(file.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        _subtitle(file),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Download button
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: AppLocalizations.of(context)!.downloadStarted,
            onPressed: () => _openDownloadUrl(context, file.id),
          ),
          // Edit / Delete popup menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditDialog(file);
              } else if (value == 'delete') {
                _confirmDelete(file);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text(AppLocalizations.of(context)!.edit),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(AppLocalizations.of(context)!.delete,
                      style: const TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      onLongPress: () => _showEditDialog(file),
    );
  }
}
