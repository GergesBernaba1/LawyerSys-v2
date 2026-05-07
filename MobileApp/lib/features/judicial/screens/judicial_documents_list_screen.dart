import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/judicial/bloc/judicial_documents_bloc.dart';
import 'package:qadaya_lawyersys/features/judicial/bloc/judicial_documents_event.dart';
import 'package:qadaya_lawyersys/features/judicial/bloc/judicial_documents_state.dart';
import 'package:qadaya_lawyersys/features/judicial/models/judicial_document.dart';
import 'package:qadaya_lawyersys/features/judicial/screens/judicial_document_detail_screen.dart';

class JudicialDocumentsListScreen extends StatefulWidget {
  const JudicialDocumentsListScreen({super.key});

  @override
  State<JudicialDocumentsListScreen> createState() => _JudicialDocumentsListScreenState();
}

class _JudicialDocumentsListScreenState extends State<JudicialDocumentsListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<JudicialDocumentsBloc>().add(LoadJudicialDocuments());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    context.read<JudicialDocumentsBloc>().add(SearchJudicialDocuments(value));
  }

  void _showForm({JudicialDocument? doc}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<JudicialDocumentsBloc>(),
        child: _JudicialDocumentForm(document: doc),
      ),
    );
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && mounted) {
      context.read<JudicialDocumentsBloc>().add(DeleteJudicialDocument(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Judicial Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showForm,
            tooltip: 'Create Document',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchJudicialDocuments,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearch,
            ),
          ),
          Expanded(
            child: BlocConsumer<JudicialDocumentsBloc, JudicialDocumentsState>(
              listener: (context, state) {
                if (state is JudicialDocumentActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
                if (state is JudicialDocumentsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${state.message}'), backgroundColor: Colors.red),
                  );
                }
              },
              builder: (context, state) {
                if (state is JudicialDocumentsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is JudicialDocumentsLoaded) {
                  if (state.documents.isEmpty) {
                    final l = AppLocalizations.of(context)!;
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.description_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(l.noDocumentsFound),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _showForm,
                            child: Text(l.createFirstDocument),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        context.read<JudicialDocumentsBloc>().add(RefreshJudicialDocuments()),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            itemCount: state.documents.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final doc = state.documents[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: Text(
                                    doc.docNum.toString(),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(doc.docType, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (doc.customerName != null)
                                      Text(doc.customerName!, style: const TextStyle(fontSize: 12)),
                                    if (doc.docDetails.isNotEmpty)
                                      Text(
                                        doc.docDetails,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _showForm(doc: doc),
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () => _confirmDelete(doc.id),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                                isThreeLine: doc.customerName != null && doc.docDetails.isNotEmpty,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<JudicialDocumentsBloc>(),
                                      child: JudicialDocumentDetailScreen(document: doc),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        _PaginationBar(
                          currentPage: state.page,
                          totalCount: state.totalCount,
                          pageSize: 20,
                          search: state.search,
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pagination bar ──────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {

  const _PaginationBar({
    required this.currentPage,
    required this.totalCount,
    required this.pageSize,
    this.search,
  });
  final int currentPage;
  final int totalCount;
  final int pageSize;
  final String? search;

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalCount / pageSize).ceil().clamp(1, 9999);
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1
                ? () => context
                    .read<JudicialDocumentsBloc>()
                    .add(LoadJudicialDocuments(page: currentPage - 1, search: search))
                : null,
          ),
          Text('$currentPage / $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages
                ? () => context
                    .read<JudicialDocumentsBloc>()
                    .add(LoadJudicialDocuments(page: currentPage + 1, search: search))
                : null,
          ),
        ],
      ),
    );
  }
}

// ── Create / Edit form ──────────────────────────────────────────────────────

class _JudicialDocumentForm extends StatefulWidget {
  const _JudicialDocumentForm({this.document});
  final JudicialDocument? document;

  @override
  State<_JudicialDocumentForm> createState() => _JudicialDocumentFormState();
}

class _JudicialDocumentFormState extends State<_JudicialDocumentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _docTypeCtrl;
  late final TextEditingController _docNumCtrl;
  late final TextEditingController _docDetailsCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _numOfAgentCtrl;
  late final TextEditingController _customerIdCtrl;

  bool get _isEdit => widget.document != null;

  @override
  void initState() {
    super.initState();
    final d = widget.document;
    _docTypeCtrl = TextEditingController(text: d?.docType ?? '');
    _docNumCtrl = TextEditingController(text: d != null ? d.docNum.toString() : '');
    _docDetailsCtrl = TextEditingController(text: d?.docDetails ?? '');
    _notesCtrl = TextEditingController(text: d?.notes ?? '');
    _numOfAgentCtrl = TextEditingController(text: d != null ? d.numOfAgent.toString() : '0');
    _customerIdCtrl = TextEditingController(text: d != null ? d.customerId.toString() : '');
  }

  @override
  void dispose() {
    _docTypeCtrl.dispose();
    _docNumCtrl.dispose();
    _docDetailsCtrl.dispose();
    _notesCtrl.dispose();
    _numOfAgentCtrl.dispose();
    _customerIdCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{
      'docType': _docTypeCtrl.text.trim(),
      'docNum': int.tryParse(_docNumCtrl.text) ?? 0,
      'docDetails': _docDetailsCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      'numOfAgent': int.tryParse(_numOfAgentCtrl.text) ?? 0,
    };

    if (_isEdit) {
      context.read<JudicialDocumentsBloc>().add(UpdateJudicialDocument(widget.document!.id, payload));
    } else {
      payload['customerId'] = int.tryParse(_customerIdCtrl.text) ?? 0;
      context.read<JudicialDocumentsBloc>().add(CreateJudicialDocument(payload));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Builder(builder: (ctx) {
                final l = AppLocalizations.of(ctx)!;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isEdit ? l.editDocument : l.createDocument,
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _docTypeCtrl,
                      decoration: InputDecoration(labelText: l.documentType),
                      validator: (v) => v == null || v.trim().isEmpty ? l.requiredField : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _docNumCtrl,
                      decoration: InputDecoration(labelText: l.documentNumber),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.trim().isEmpty ? l.requiredField : null,
                    ),
                    const SizedBox(height: 12),
                    if (!_isEdit) ...[
                      TextFormField(
                        controller: _customerIdCtrl,
                        decoration: InputDecoration(labelText: l.customerId),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          return (n == null || n <= 0) ? l.requiredField : null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _numOfAgentCtrl,
                      decoration: InputDecoration(labelText: l.agentNumber),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _docDetailsCtrl,
                      decoration: InputDecoration(labelText: l.details),
                      maxLines: 3,
                      validator: (v) => v == null || v.trim().isEmpty ? l.requiredField : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: InputDecoration(labelText: l.notes),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l.cancel),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _submit,
                          child: Text(_isEdit ? l.save : l.createDocument),
                        ),
                      ],
                    ),
                  ],
                );
              },),
            ],
          ),
        ),
      ),
    );
  }
}
