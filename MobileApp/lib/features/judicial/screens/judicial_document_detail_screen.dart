import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
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
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        return AlertDialog(
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
        );
      },
    );
    if ((confirmed ?? false) && context.mounted) {
      context.read<JudicialDocumentsBloc>().add(DeleteJudicialDocument(document.id));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${l.document} #${document.docNum}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: l.edit,
            onPressed: () => _showForm(context, doc: document),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: l.delete,
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
                  label: l.documentType,
                  value: document.docType,
                  labelColor: primaryColor,
                ),
                const Divider(),
                _InfoRow(
                  label: l.documentNumber,
                  value: document.docNum.toString(),
                  labelColor: primaryColor,
                ),
                const Divider(),
                _InfoRow(
                  label: l.customer,
                  value: document.customerName ?? document.customerId.toString(),
                  labelColor: primaryColor,
                ),
                const Divider(),
                _InfoRow(
                  label: l.agentsCount,
                  value: document.numOfAgent.toString(),
                  labelColor: primaryColor,
                ),
                if (document.docDetails.isNotEmpty) ...[
                  const Divider(),
                  _InfoRow(
                    label: l.details,
                    value: document.docDetails,
                    labelColor: primaryColor,
                    multiline: true,
                  ),
                ],
                if (document.notes.isNotEmpty) ...[
                  const Divider(),
                  _InfoRow(
                    label: l.notes,
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
              Builder(builder: (ctx) {
                final l = AppLocalizations.of(ctx)!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.editDocument,
                      style: Theme.of(ctx)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _docTypeCtrl,
                      decoration: InputDecoration(labelText: l.documentType),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? l.requiredField : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _docNumCtrl,
                      decoration: InputDecoration(labelText: l.documentNumber),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? l.requiredField : null,
                    ),
                    const SizedBox(height: 12),
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
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? l.requiredField : null,
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
                          child: Text(l.save),
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
