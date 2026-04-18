import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

// TODO: localize all hardcoded strings using AppLocalizations
// import '../../../core/localization/app_localizations.dart';
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
            // TODO: localize
            const SnackBar(content: Text('Could not open the download URL.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // TODO: localize
          SnackBar(content: Text('Download failed: $e')),
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

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        // TODO: localize 'Create File'
        title: const Text('Create File'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  // TODO: localize 'Title'
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descController,
                  // TODO: localize 'Description'
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: categoryController,
                  // TODO: localize 'Category'
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            // TODO: localize 'Cancel'
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            // TODO: localize 'Create'
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
            child: const Text('Create'),
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

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        // TODO: localize 'Edit File'
        title: const Text('Edit File'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            // TODO: localize 'Save'
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(FileModel file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        // TODO: localize 'Delete File'
        title: const Text('Delete File'),
        // TODO: localize
        content: Text('Are you sure you want to delete "${file.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            // TODO: localize 'Delete'
            child: const Text('Delete'),
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
            // TODO: localize 'Files'
            title: const Text('Files'),
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: _searchController,
                  // TODO: localize 'Search files...'
                  decoration: InputDecoration(
                    hintText: 'Search files...',
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
            tooltip: 'Add file', // TODO: localize
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
        // TODO: localize 'Error'
        child: Text('Error: ${state.message}'),
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
      return const Center(
        // TODO: localize 'No files found'
        child: Text('No files found'),
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
            tooltip: 'Download', // TODO: localize
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
              const PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  // TODO: localize 'Edit'
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  // TODO: localize 'Delete'
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
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
