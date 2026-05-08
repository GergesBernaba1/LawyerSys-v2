import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/judicial/bloc/judicial_documents_bloc.dart';
import 'package:qadaya_lawyersys/features/judicial/bloc/judicial_documents_event.dart';
import 'package:qadaya_lawyersys/features/judicial/bloc/judicial_documents_state.dart';
import 'package:qadaya_lawyersys/features/judicial/models/judicial_document.dart';

const _kPrimary = Color(0xFF14345A);
const _kPrimaryLight = Color(0xFF2D6A87);
const _kText = Color(0xFF0F172A);
const _kTextSecondary = Color(0xFF5F7085);
const _kBg = Color(0xFFF3F6FA);

class JudicialDocumentDetailScreen extends StatelessWidget {
  const JudicialDocumentDetailScreen({super.key, required this.document});
  final JudicialDocument document;

  void _showEditForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<JudicialDocumentsBloc>(),
        child: _EditForm(document: document),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppLocalizations l) async {
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
    if ((confirmed ?? false) && context.mounted) {
      context
          .read<JudicialDocumentsBloc>()
          .add(DeleteJudicialDocument(document.id));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return BlocListener<JudicialDocumentsBloc, JudicialDocumentsState>(
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
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          title: Text('${l.document} #${document.docNum}'),
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l.edit,
              onPressed: () => _showEditForm(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l.delete,
              color: Colors.redAccent,
              onPressed: () => _confirmDelete(context, l),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildInfoCard(l),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kPrimary, _kPrimaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.docType,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (document.customerName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      document.customerName!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildInfoCard(AppLocalizations l) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kText.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(
                Icons.tag_outlined,
                l.documentNumber,
                document.docNum.toString(),
              ),
              _divider(),
              _infoRow(
                Icons.person_outline,
                l.customer,
                document.customerName ?? document.customerId.toString(),
              ),
              _divider(),
              _infoRow(
                Icons.groups_outlined,
                l.agentsCount,
                document.numOfAgent.toString(),
              ),
              if (document.docDetails.isNotEmpty) ...[
                _divider(),
                _multilineRow(
                  Icons.notes_outlined,
                  l.details,
                  document.docDetails,
                ),
              ],
              if (document.notes.isNotEmpty) ...[
                _divider(),
                _multilineRow(
                  Icons.sticky_note_2_outlined,
                  l.notes,
                  document.notes,
                ),
              ],
            ],
          ),
        ),
      );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _kPrimaryLight),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: _kTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kText,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _multilineRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: _kPrimaryLight),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _kTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 14, color: _kText, height: 1.5),
            ),
          ],
        ),
      );

  Widget _divider() =>
      const Divider(height: 1, color: Color(0xFFEEF2F7));
}

// ── Edit-only form (no customer field, no create logic) ─────────────────────

class _EditForm extends StatefulWidget {
  const _EditForm({required this.document});
  final JudicialDocument document;

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _docTypeCtrl;
  late final TextEditingController _docNumCtrl;
  late final TextEditingController _docDetailsCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _numOfAgentCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.document;
    _docTypeCtrl = TextEditingController(text: d.docType);
    _docNumCtrl = TextEditingController(text: d.docNum.toString());
    _docDetailsCtrl = TextEditingController(text: d.docDetails);
    _notesCtrl = TextEditingController(text: d.notes);
    _numOfAgentCtrl = TextEditingController(text: d.numOfAgent.toString());
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
    context.read<JudicialDocumentsBloc>().add(
          UpdateJudicialDocument(widget.document.id, {
            'docType': _docTypeCtrl.text.trim(),
            'docNum': int.tryParse(_docNumCtrl.text) ?? 0,
            'docDetails': _docDetailsCtrl.text.trim(),
            'notes': _notesCtrl.text.trim(),
            'numOfAgent': int.tryParse(_numOfAgentCtrl.text) ?? 0,
          }),
        );
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

    return Padding(
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
                l.editDocument,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _docTypeCtrl,
                decoration:
                    _dec(l.documentType, Icons.description_outlined),
                validator: (v) => v == null || v.trim().isEmpty
                    ? l.requiredField
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _docNumCtrl,
                decoration: _dec(l.documentNumber, Icons.tag_outlined),
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
                    child: Text(l.save),
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
