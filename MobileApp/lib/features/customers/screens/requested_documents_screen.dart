import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/customers/bloc/customers_bloc.dart';
import 'package:qadaya_lawyersys/features/customers/bloc/customers_event.dart';
import 'package:qadaya_lawyersys/features/customers/bloc/customers_state.dart';
import 'package:qadaya_lawyersys/features/customers/models/customer_requested_document.dart';
import 'package:qadaya_lawyersys/shared/widgets/skeleton_loader.dart';

class RequestedDocumentsScreen extends StatefulWidget {

  const RequestedDocumentsScreen({super.key, required this.caseCode});
  final int caseCode;

  @override
  State<RequestedDocumentsScreen> createState() =>
      _RequestedDocumentsScreenState();
}

class _RequestedDocumentsScreenState extends State<RequestedDocumentsScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<CustomersBloc>()
        .add(LoadRequestedDocuments(widget.caseCode));
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'submitted':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  void _showSubmitDialog(CustomerRequestedDocument document) {
    final filePathController = TextEditingController();
    final notesController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<CustomersBloc>(),
        child: BlocListener<CustomersBloc, CustomersState>(
          listener: (context, state) {
            if (state is RequestedDocumentSubmitted) {
              final l = AppLocalizations.of(context)!;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.documentSubmittedSuccessfully)),
              );
              // Reload the list
              context
                  .read<CustomersBloc>()
                  .add(LoadRequestedDocuments(widget.caseCode));
            } else if (state is CustomersError) {
              final l = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${l.error}: ${state.message}')),
              );
            }
          },
          child: AlertDialog(
            title: Text('${AppLocalizations.of(context)!.submit}: ${document.title}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    document.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (document.dueDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Due: ${document.dueDate!.year}-${document.dueDate!.month.toString().padLeft(2, '0')}-${document.dueDate!.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Builder(builder: (ctx) {
                    final l = AppLocalizations.of(ctx)!;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: filePathController,
                          decoration: InputDecoration(
                            labelText: l.filePath,
                            hintText: '/storage/emulated/0/Documents/document.pdf',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: l.notesOptional,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    );
                  },),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              BlocBuilder<CustomersBloc, CustomersState>(
                builder: (context, state) {
                  final isSubmitting = state is RequestedDocumentSubmitting;
                  return ElevatedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            final filePath =
                                filePathController.text.trim();
                            if (filePath.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context)!.pleaseEnterFilePath,
                                  ),
                                ),
                              );
                              return;
                            }
                            context.read<CustomersBloc>().add(
                                  SubmitRequestedDocument(
                                    caseCode: widget.caseCode,
                                    requestId: document.id,
                                    filePath: filePath,
                                    notes: notesController.text.trim(),
                                  ),
                                );
                          },
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.upload),
                    label: Text(isSubmitting
                        ? AppLocalizations.of(context)!.submitting
                        : AppLocalizations.of(context)!.submit,),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      filePathController.dispose();
      notesController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizer.requestedDocuments),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context
                .read<CustomersBloc>()
                .add(LoadRequestedDocuments(widget.caseCode)),
          ),
        ],
      ),
      body: BlocBuilder<CustomersBloc, CustomersState>(
        builder: (context, state) {
          if (state is CustomersLoading) {
            return const ListSkeleton();
          }

          if (state is CustomersError) {
            return Center(
              child:
                  Text('${localizer.error}: ${state.message}'),
            );
          }

          if (state is RequestedDocumentsLoaded) {
            final documents = state.documents;

            if (documents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.description_outlined,
                        size: 64, color: Colors.grey,),
                    const SizedBox(height: 12),
                    Text(
                      localizer.noRequestedDocuments,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _statusColor(doc.status).withValues(alpha: 0.2),
                      child: Icon(
                        doc.isApproved
                            ? Icons.check_circle
                            : doc.isRejected
                                ? Icons.cancel
                                : doc.isSubmitted
                                    ? Icons.upload_file
                                    : Icons.pending,
                        color: _statusColor(doc.status),
                      ),
                    ),
                    title: Text(
                      doc.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.description),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2,),
                              decoration: BoxDecoration(
                                color: _statusColor(doc.status)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                doc.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor(doc.status),
                                ),
                              ),
                            ),
                            if (doc.dueDate != null) ...[
                              const SizedBox(width: 8),
                              const Text(
                                r'Due: ${doc.dueDate!.month}/${doc.dueDate!.day}',
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: doc.isPending
                        ? IconButton(
                            icon: const Icon(Icons.upload_file),
                            onPressed: () => _showSubmitDialog(doc),
                          )
                        : null,
                    isThreeLine: true,
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
