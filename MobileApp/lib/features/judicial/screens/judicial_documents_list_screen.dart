import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/customers/models/customer.dart';
import 'package:qadaya_lawyersys/features/customers/repositories/customers_repository.dart';
import 'package:qadaya_lawyersys/features/judicial/bloc/judicial_documents_bloc.dart';
import 'package:qadaya_lawyersys/features/judicial/bloc/judicial_documents_event.dart';
import 'package:qadaya_lawyersys/features/judicial/bloc/judicial_documents_state.dart';
import 'package:qadaya_lawyersys/features/judicial/models/judicial_document.dart';
import 'package:qadaya_lawyersys/features/judicial/screens/judicial_document_detail_screen.dart';

const _kPrimary = Color(0xFF14345A);
const _kPrimaryLight = Color(0xFF2D6A87);
const _kText = Color(0xFF0F172A);
const _kTextSecondary = Color(0xFF5F7085);
const _kBg = Color(0xFFF3F6FA);

class JudicialDocumentsListScreen extends StatefulWidget {
  const JudicialDocumentsListScreen({super.key});

  @override
  State<JudicialDocumentsListScreen> createState() =>
      _JudicialDocumentsListScreenState();
}

class _JudicialDocumentsListScreenState
    extends State<JudicialDocumentsListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<JudicialDocumentsBloc>().add(LoadJudicialDocuments());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context
            .read<JudicialDocumentsBloc>()
            .add(SearchJudicialDocuments(value));
      }
    });
  }

  void _showForm({JudicialDocument? doc}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<JudicialDocumentsBloc>(),
        child: _JudicialDocumentForm(document: doc),
      ),
    );
  }

  Future<void> _confirmDelete(int id, AppLocalizations l) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteDocument),
        content: Text(l.deleteDocumentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete, style: const TextStyle(color: Colors.red)),
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
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(l.judicialDocuments),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l.createDocument,
            onPressed: _showForm,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: _kPrimary,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l.searchJudicialDocuments,
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: _onSearchChanged,
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
                    SnackBar(
                      content: Text('${l.error}: ${state.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is JudicialDocumentsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: _kPrimary),
                  );
                }

                if (state is JudicialDocumentsLoaded) {
                  if (state.documents.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: _kPrimary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l.noDocumentsFound,
                            style: const TextStyle(color: _kTextSecondary),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.add),
                            label: Text(l.createFirstDocument),
                            onPressed: _showForm,
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: _kPrimary,
                    onRefresh: () async => context
                        .read<JudicialDocumentsBloc>()
                        .add(RefreshJudicialDocuments()),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                            itemCount: state.documents.length,
                            itemBuilder: (context, index) {
                              final doc = state.documents[index];
                              return _DocumentTile(
                                doc: doc,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => BlocProvider.value(
                                      value: context
                                          .read<JudicialDocumentsBloc>(),
                                      child: JudicialDocumentDetailScreen(
                        document: doc,
                      ),
                                    ),
                                  ),
                                ),
                                onEdit: () => _showForm(doc: doc),
                                onDelete: () => _confirmDelete(doc.id, l),
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

// ── Document tile ───────────────────────────────────────────────────────────

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.doc,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final JudicialDocument doc;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _kText.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        onTap: onTap,
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: _kPrimary.withValues(alpha: 0.1),
          child: Text(
            doc.docNum.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
        ),
        title: Text(
          doc.docType,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (doc.customerName != null)
              Text(
                doc.customerName!,
                style: const TextStyle(fontSize: 12, color: _kTextSecondary),
              ),
            if (doc.docDetails.isNotEmpty)
              Text(
                doc.docDetails,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: _kTextSecondary),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: _kPrimaryLight,
              tooltip: l.edit,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red,
              tooltip: l.delete,
              onPressed: onDelete,
            ),
          ],
        ),
        isThreeLine:
            doc.customerName != null && doc.docDetails.isNotEmpty,
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
    final totalPages =
        (totalCount / pageSize).ceil().clamp(1, 9999);
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5EAF0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: _kPrimary),
            onPressed: currentPage > 1
                ? () => context.read<JudicialDocumentsBloc>().add(
                      LoadJudicialDocuments(
                        page: currentPage - 1,
                        search: search,
                      ),
                    )
                : null,
          ),
          Text(
            '$currentPage / $totalPages',
            style: const TextStyle(fontWeight: FontWeight.w600, color: _kText),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: _kPrimary),
            onPressed: currentPage < totalPages
                ? () => context.read<JudicialDocumentsBloc>().add(
                      LoadJudicialDocuments(
                        page: currentPage + 1,
                        search: search,
                      ),
                    )
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
  State<_JudicialDocumentForm> createState() =>
      _JudicialDocumentFormState();
}

class _JudicialDocumentFormState extends State<_JudicialDocumentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _docTypeCtrl;
  late final TextEditingController _docNumCtrl;
  late final TextEditingController _docDetailsCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _numOfAgentCtrl;

  bool get _isEdit => widget.document != null;

  // Customer dropdown state (create only)
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  bool _loadingCustomers = false;

  @override
  void initState() {
    super.initState();
    final d = widget.document;
    _docTypeCtrl = TextEditingController(text: d?.docType ?? '');
    _docNumCtrl =
        TextEditingController(text: d != null ? d.docNum.toString() : '');
    _docDetailsCtrl = TextEditingController(text: d?.docDetails ?? '');
    _notesCtrl = TextEditingController(text: d?.notes ?? '');
    _numOfAgentCtrl = TextEditingController(
      text: d != null ? d.numOfAgent.toString() : '0',
    );

    if (!_isEdit) _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _loadingCustomers = true);
    try {
      final repo =
          RepositoryProvider.of<CustomersRepository>(context);
      final list = await repo.getCustomers(pageSize: 200);
      if (mounted) setState(() => _customers = list);
    } catch (_) {
      // silently fail; user can still proceed if needed
    } finally {
      if (mounted) setState(() => _loadingCustomers = false);
    }
  }

  @override
  void dispose() {
    _docTypeCtrl.dispose();
    _docNumCtrl.dispose();
    _docDetailsCtrl.dispose();
    _notesCtrl.dispose();
    _numOfAgentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final l = AppLocalizations.of(context)!;

    if (!_isEdit && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.requiredField)),
      );
      return;
    }

    final payload = <String, dynamic>{
      'docType': _docTypeCtrl.text.trim(),
      'docNum': int.tryParse(_docNumCtrl.text) ?? 0,
      'docDetails': _docDetailsCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      'numOfAgent': int.tryParse(_numOfAgentCtrl.text) ?? 0,
    };

    if (_isEdit) {
      context
          .read<JudicialDocumentsBloc>()
          .add(UpdateJudicialDocument(widget.document!.id, payload));
    } else {
      payload['customerId'] =
          int.tryParse(_selectedCustomer!.customerId) ?? 0;
      context
          .read<JudicialDocumentsBloc>()
          .add(CreateJudicialDocument(payload));
    }

    Navigator.pop(context);
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _kPrimaryLight, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: _kPrimary.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return BlocListener<JudicialDocumentsBloc, JudicialDocumentsState>(
      listener: (context, state) {
        if (state is JudicialDocumentActionSuccess) {
          Navigator.pop(context);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isEdit ? l.editDocument : l.createDocument,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Customer dropdown (create only)
                if (!_isEdit) ...[
                  if (_loadingCustomers)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(color: _kPrimary),
                      ),
                    )
                  else
                    DropdownButtonFormField<Customer>(
                      initialValue: _selectedCustomer,
                      decoration: _dec(l.customer, Icons.person_outline),
                      hint: Text(l.customer),
                      isExpanded: true,
                      items: _customers
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c.fullName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (c) => setState(() => _selectedCustomer = c),
                      validator: (v) => v == null ? l.requiredField : null,
                    ),
                  const SizedBox(height: 12),
                ],

                TextFormField(
                  controller: _docTypeCtrl,
                  decoration: _dec(l.documentType, Icons.description_outlined),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? l.requiredField
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _docNumCtrl,
                  decoration:
                      _dec(l.documentNumber, Icons.tag_outlined),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? l.requiredField
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _numOfAgentCtrl,
                  decoration: _dec(l.agentNumber, Icons.groups_outlined),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _docDetailsCtrl,
                  decoration: _dec(l.details, Icons.notes_outlined),
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? l.requiredField
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: _dec(l.notes, Icons.sticky_note_2_outlined),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        l.cancel,
                        style: const TextStyle(color: _kTextSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _submit,
                      child: Text(_isEdit ? l.save : l.createDocument),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
