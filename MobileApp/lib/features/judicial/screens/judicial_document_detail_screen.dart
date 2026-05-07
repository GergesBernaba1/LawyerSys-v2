import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/features/judicial/bloc/judicial_documents_bloc.dart';
import 'package:qadaya_lawyersys/features/judicial/bloc/judicial_documents_event.dart';
import 'package:qadaya_lawyersys/features/judicial/models/judicial_document.dart';

class JudicialDocumentDetailScreen extends StatelessWidget {

  const JudicialDocumentDetailScreen({super.key, required this.document});
  final JudicialDocument document;

  void _showForm(BuildContext context, {JudicialDocument? doc}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<JudicialDocumentsBloc>(),
        child: _JudicialDocumentFormBridge(document: doc),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && context.mounted) {
      context.read<JudicialDocumentsBloc>().add(DeleteJudicialDocument(document.id));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Document #${document.docNum}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => _showForm(context, doc: document),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _InfoRow(
                  label: 'Doc Type',
                  value: document.docType,
                  labelColor: primaryColor,
                ),
                const Divider(),
                _InfoRow(
                  label: 'Doc Number',
                  value: document.docNum.toString(),
                  labelColor: primaryColor,
                ),
                const Divider(),
                _InfoRow(
                  label: 'Customer',
                  value: document.customerName ?? document.customerId.toString(),
                  labelColor: primaryColor,
                ),
                const Divider(),
                _InfoRow(
                  label: 'Agents Count',
                  value: document.numOfAgent.toString(),
                  labelColor: primaryColor,
                ),
                if (document.docDetails.isNotEmpty) ...[
                  const Divider(),
                  _InfoRow(
                    label: 'Details',
                    value: document.docDetails,
                    labelColor: primaryColor,
                    multiline: true,
                  ),
                ],
                if (document.notes.isNotEmpty) ...[
                  const Divider(),
                  _InfoRow(
                    label: 'Notes',
                    value: document.notes,
                    labelColor: primaryColor,
                    multiline: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {

  const _InfoRow({
    required this.label,
    required this.value,
    required this.labelColor,
    this.multiline = false,
  });
  final String label;
  final String value;
  final Color labelColor;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: multiline
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),),
                const SizedBox(height: 4),
                Text(value),
              ],
            )
          : Row(
              children: [
                Text(label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),),
                const SizedBox(width: 8),
                Expanded(child: Text(value, textAlign: TextAlign.end)),
              ],
            ),
    );
  }
}

/// Bridge widget to access the internal _JudicialDocumentForm from list_screen.
/// We re-expose the form by importing it and delegating to its usage pattern.
class _JudicialDocumentFormBridge extends StatefulWidget {
  const _JudicialDocumentFormBridge({this.document});
  final JudicialDocument? document;

  @override
  State<_JudicialDocumentFormBridge> createState() =>
      _JudicialDocumentFormBridgeState();
}

class _JudicialDocumentFormBridgeState
    extends State<_JudicialDocumentFormBridge> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _docTypeCtrl;
  late final TextEditingController _docNumCtrl;
  late final TextEditingController _docDetailsCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _numOfAgentCtrl;

  bool get _isEdit => widget.document != null;

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
        text: d != null ? d.numOfAgent.toString() : '0',);
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
              Text(
                'Edit Document',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _docTypeCtrl,
                decoration: const InputDecoration(labelText: 'Document Type'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _docNumCtrl,
                decoration:
                    const InputDecoration(labelText: 'Document Number'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numOfAgentCtrl,
                decoration: const InputDecoration(labelText: 'Agent Number'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _docDetailsCtrl,
                decoration: const InputDecoration(labelText: 'Details'),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
