import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/document-generation/bloc/doc_generation_bloc.dart';
import 'package:qadaya_lawyersys/features/document-generation/bloc/doc_generation_event.dart';
import 'package:qadaya_lawyersys/features/document-generation/bloc/doc_generation_state.dart';
import 'package:qadaya_lawyersys/features/document-generation/models/doc_gen_models.dart';

class DocGenerationScreen extends StatefulWidget {
  const DocGenerationScreen({super.key});

  @override
  State<DocGenerationScreen> createState() => _DocGenerationScreenState();
}

class _DocGenerationScreenState extends State<DocGenerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<DocGenerationBloc>().add(LoadDocTemplates());

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 1) {
          context.read<DocGenerationBloc>().add(LoadDocHistory());
        } else if (_tabController.index == 2) {
          context.read<DocGenerationBloc>().add(LoadDocDrafts());
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.documentGeneration),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.generateDocument),
            Tab(text: AppLocalizations.of(context)!.caseHistory),
            Tab(text: AppLocalizations.of(context)!.newDraft),
          ],
        ),
      ),
      body: BlocListener<DocGenerationBloc, DocGenState>(
        listener: (context, state) {
          if (state is DocGenError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${AppLocalizations.of(context)!.error}: ${state.message}')),
            );
          } else if (state is DocGenOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: const [
            _GenerateTab(),
            _HistoryTab(),
            _DraftsTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — Generate
// ---------------------------------------------------------------------------

class _GenerateTab extends StatefulWidget {
  const _GenerateTab();

  @override
  State<_GenerateTab> createState() => _GenerateTabState();
}

class _GenerateTabState extends State<_GenerateTab> {
  DocTemplate? _selectedTemplate;
  final _caseCodeController = TextEditingController();
  String _language = 'en';

  // field key → controller / value
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, String?> _selectValues = {};
  final Map<String, DateTime?> _dateValues = {};

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _caseCodeController.dispose();
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _selectTemplate(DocTemplate template) {
    // dispose old controllers
    for (final c in _textControllers.values) {
      c.dispose();
    }
    _textControllers.clear();
    _selectValues.clear();
    _dateValues.clear();

    for (final field in template.fields) {
      if (field.fieldType == 'text' || field.fieldType == 'number') {
        _textControllers[field.key] = TextEditingController();
      } else if (field.fieldType == 'select') {
        _selectValues[field.key] = null;
      } else if (field.fieldType == 'date') {
        _dateValues[field.key] = null;
      }
    }
    setState(() => _selectedTemplate = template);
  }

  Future<void> _pickDate(DocTemplateField field) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateValues[field.key] ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dateValues[field.key] = picked);
    }
  }

  Map<String, dynamic> _collectFieldValues() {
    final values = <String, dynamic>{};
    _textControllers.forEach((key, ctrl) => values[key] = ctrl.text);
    _selectValues.forEach((key, val) => values[key] = val);
    _dateValues.forEach((key, val) {
      if (val != null) values[key] = val.toIso8601String().split('T').first;
    });
    return values;
  }

  void _generate() {
    if (_selectedTemplate == null) return;
    if (!_formKey.currentState!.validate()) return;

    context.read<DocGenerationBloc>().add(
          GenerateDocument(
            templateId: _selectedTemplate!.id,
            fieldValues: _collectFieldValues(),
            language: _language,
            caseCode:
                _caseCodeController.text.trim().isEmpty ? null : _caseCodeController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocGenerationBloc, DocGenState>(
      builder: (context, state) {
        final isLoading = state is DocGenLoading;

        List<DocTemplate> templates = [];
        if (state is DocTemplatesLoaded) {
          templates = state.templates;
        }

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Language picker
              Row(
                children: [
                  Text('${AppLocalizations.of(context)!.language}: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(AppLocalizations.of(context)!.english),
                    selected: _language == 'en',
                    onSelected: (_) => setState(() => _language = 'en'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(AppLocalizations.of(context)!.arabic),
                    selected: _language == 'ar',
                    onSelected: (_) {
                      setState(() => _language = 'ar');
                      context.read<DocGenerationBloc>().add(
                            LoadDocTemplates(language: 'ar'),
                          );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Case code field (optional)
              TextFormField(
                controller: _caseCodeController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.caseCode,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Template list
              Text(AppLocalizations.of(context)!.selectTemplate,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
              const SizedBox(height: 8),

              if (state is DocGenLoading && templates.isEmpty)
                const Center(child: CircularProgressIndicator()),

              if (templates.isEmpty && state is! DocGenLoading)
                Text(AppLocalizations.of(context)!.noTemplatesFound,
                    style: const TextStyle(color: Colors.grey),),

              RadioGroup<String>(
                groupValue: _selectedTemplate?.id,
                onChanged: (id) {
                  if (id == null) return;
                  final template = templates.firstWhere((t) => t.id == id);
                  _selectTemplate(template);
                },
                child: Column(
                  children: templates.map((template) {
                    final isSelected = _selectedTemplate?.id == template.id;
                    return Card(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                          : null,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: RadioListTile<String>(
                        value: template.id,
                        title: Text(template.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),),
                        subtitle: template.description != null
                            ? Text(template.description!)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Dynamic field form
              if (_selectedTemplate != null) ...[
                const Divider(height: 32),
                Text(AppLocalizations.of(context)!.fillInFields,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                const SizedBox(height: 8),
                ..._selectedTemplate!.fields.map(_buildField),
                const SizedBox(height: 16),
              ],

              // Generated result card
              if (state is DocGeneratedSuccess) ...[
                Card(
                  color: Colors.green.withValues(alpha: 0.15),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(state.doc.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),),
                    subtitle: Text(
                      '${AppLocalizations.of(context)!.generatedOn}: ${state.doc.generatedAt.toLocal().toString().split('.').first}',
                    ),
                  ),
                ),
              ],

              // Generate button
              if (_selectedTemplate != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _generate,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.article),
                    label: Text(AppLocalizations.of(context)!.generateDocument),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildField(DocTemplateField field) {
    switch (field.fieldType) {
      case 'select':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownMenu<String>(
            initialSelection: _selectValues[field.key],
            label: Text(field.label),
            expandedInsets: EdgeInsets.zero,
            onSelected: (val) => setState(() => _selectValues[field.key] = val),
            dropdownMenuEntries: (field.options ?? [])
                .map((opt) => DropdownMenuEntry(value: opt, label: opt))
                .toList(),
            errorText: (field.required && _selectValues[field.key] == null)
                ? '${field.label} ${AppLocalizations.of(context)!.isRequired}'
                : null,
          ),
        );

      case 'date':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FormField<DateTime>(
            validator: field.required
                ? (val) => _dateValues[field.key] == null
                    ? '${field.label} ${AppLocalizations.of(context)!.isRequired}'
                    : null
                : null,
            builder: (formState) {
              final picked = _dateValues[field.key];
              return InkWell(
                onTap: () => _pickDate(field),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: field.label,
                    border: const OutlineInputBorder(),
                    errorText: formState.errorText,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    picked != null
                        ? picked.toLocal().toString().split(' ').first
                        : AppLocalizations.of(context)!.pickADate,
                    style: TextStyle(
                      color: picked != null ? null : Colors.grey,
                    ),
                  ),
                ),
              );
            },
          ),
        );

      case 'number':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: _textControllers[field.key],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: field.label,
              border: const OutlineInputBorder(),
            ),
            validator: field.required
                ? (val) =>
                    (val == null || val.isEmpty) ? '${field.label} ${AppLocalizations.of(context)!.isRequired}' : null
                : null,
          ),
        );

      default: // text
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: _textControllers[field.key],
            decoration: InputDecoration(
              labelText: field.label,
              border: const OutlineInputBorder(),
            ),
            validator: field.required
                ? (val) =>
                    (val == null || val.isEmpty) ? '${field.label} ${AppLocalizations.of(context)!.isRequired}' : null
                : null,
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Tab 2 — History
// ---------------------------------------------------------------------------

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocGenerationBloc, DocGenState>(
      builder: (context, state) {
        if (state is DocGenLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is DocHistoryLoaded) {
          final history = state.history;
          if (history.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<DocGenerationBloc>().add(LoadDocHistory()),
              child: ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.history, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(AppLocalizations.of(context)!.noDocumentsFound,
                            style: const TextStyle(color: Colors.grey),),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<DocGenerationBloc>().add(LoadDocHistory()),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final doc = history[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.description, color: Colors.blue),
                    title: Text(doc.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (doc.templateName != null)
                          Text('${AppLocalizations.of(context)!.templateLabel}: ${doc.templateName}'),
                        if (doc.caseCode != null)
                          Text('${AppLocalizations.of(context)!.caseLabel}: ${doc.caseCode}'),
                        Text(
                            '${AppLocalizations.of(context)!.generatedLabel}: ${doc.generatedAt.toLocal().toString().split('.').first}',),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              context.read<DocGenerationBloc>().add(LoadDocHistory()),
          child: ListView(children: const [SizedBox(height: 0)]),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3 — Drafts
// ---------------------------------------------------------------------------

class _DraftsTab extends StatelessWidget {
  const _DraftsTab();

  void _showCreateDraftDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.newDraft),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: l10n.title,
                  border: const OutlineInputBorder(),
                ),
                validator: (val) =>
                    (val == null || val.isEmpty) ? '${l10n.title} ${l10n.isRequired}' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: contentCtrl,
                decoration: InputDecoration(
                  labelText: l10n.content,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (val) =>
                    (val == null || val.isEmpty) ? '${l10n.content} ${l10n.isRequired}' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<DocGenerationBloc>().add(
                      CreateDocDraft(
                        title: titleCtrl.text.trim(),
                        content: contentCtrl.text.trim(),
                      ),
                    );
                Navigator.pop(dialogCtx);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DocDraft draft) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.deleteDraft),
        content: Text('${l10n.delete} "${draft.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<DocGenerationBloc>().add(DeleteDocDraft(draft.id));
              Navigator.pop(dialogCtx);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocGenerationBloc, DocGenState>(
      builder: (context, state) {
        List<DocDraft> drafts = [];
        final bool isLoading = state is DocGenLoading;

        if (state is DocDraftsLoaded) {
          drafts = state.drafts;
        }

        Widget body;
        if (isLoading) {
          body = const Center(child: CircularProgressIndicator());
        } else if (drafts.isEmpty) {
          body = RefreshIndicator(
            onRefresh: () async =>
                context.read<DocGenerationBloc>().add(LoadDocDrafts()),
            child: ListView(
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.drafts, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(AppLocalizations.of(context)!.noData,
                          style: const TextStyle(color: Colors.grey),),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          body = RefreshIndicator(
            onRefresh: () async =>
                context.read<DocGenerationBloc>().add(LoadDocDrafts()),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: drafts.length,
              itemBuilder: (context, index) {
                final draft = drafts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.edit_document, color: Colors.orange),
                    title: Text(draft.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),),
                    subtitle: Text(
                      '${AppLocalizations.of(context)!.generatedOn}: ${draft.createdAt.toLocal().toString().split('.').first}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(context, draft),
                    ),
                  ),
                );
              },
            ),
          );
        }

        return Scaffold(
          body: body,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateDraftDialog(context),
            tooltip: AppLocalizations.of(context)!.newDraft,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
