import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/doc_generation_bloc.dart';
import '../bloc/doc_generation_event.dart';
import '../bloc/doc_generation_state.dart';
import '../models/doc_gen_models.dart';

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
        // TODO: localize 'Document Generation'
        title: const Text('Document Generation'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            // TODO: localize tab labels
            Tab(text: 'Generate'),
            Tab(text: 'History'),
            Tab(text: 'Drafts'),
          ],
        ),
      ),
      body: BlocListener<DocGenerationBloc, DocGenState>(
        listener: (context, state) {
          if (state is DocGenError) {
            ScaffoldMessenger.of(context).showSnackBar(
              // TODO: localize 'Error'
              SnackBar(content: Text('Error: ${state.message}')),
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
                  // TODO: localize 'Language'
                  const Text('Language: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    // TODO: localize 'English'
                    label: const Text('English'),
                    selected: _language == 'en',
                    onSelected: (_) => setState(() => _language = 'en'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    // TODO: localize 'Arabic'
                    label: const Text('Arabic'),
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
                // TODO: localize label/hint
                decoration: const InputDecoration(
                  labelText: 'Case Code (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Template list
              // TODO: localize 'Select Template'
              const Text('Select Template',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              if (state is DocGenLoading && templates.isEmpty)
                const Center(child: CircularProgressIndicator()),

              if (templates.isEmpty && state is! DocGenLoading)
                // TODO: localize 'No templates available'
                const Text('No templates available.',
                    style: TextStyle(color: Colors.grey)),

              ...templates.map((template) {
                final isSelected = _selectedTemplate?.id == template.id;
                return Card(
                  color: isSelected
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                      : null,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<String>(
                    value: template.id,
                    groupValue: _selectedTemplate?.id,
                    onChanged: (_) => _selectTemplate(template),
                    title: Text(template.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: template.description != null
                        ? Text(template.description!)
                        : null,
                  ),
                );
              }),

              // Dynamic field form
              if (_selectedTemplate != null) ...[
                const Divider(height: 32),
                // TODO: localize 'Fill in Fields'
                const Text('Fill in Fields',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._selectedTemplate!.fields.map((field) => _buildField(field)),
                const SizedBox(height: 16),
              ],

              // Generated result card
              if (state is DocGeneratedSuccess) ...[
                Card(
                  color: Colors.green.withValues(alpha: 0.15),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    // TODO: localize 'Document Generated'
                    title: Text(state.doc.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      // TODO: localize 'Generated on'
                      'Generated on: ${state.doc.generatedAt.toLocal().toString().split('.').first}',
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
                    // TODO: localize 'Generate Document'
                    label: const Text('Generate Document'),
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
          child: DropdownButtonFormField<String>(
            value: _selectValues[field.key],
            decoration: InputDecoration(
              labelText: field.label,
              border: const OutlineInputBorder(),
            ),
            items: (field.options ?? [])
                .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                .toList(),
            onChanged: (val) => setState(() => _selectValues[field.key] = val),
            validator: field.required
                ? (val) =>
                    val == null ? '${field.label} is required' : null // TODO: localize
                : null,
          ),
        );

      case 'date':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FormField<DateTime>(
            validator: field.required
                ? (val) => _dateValues[field.key] == null
                    ? '${field.label} is required' // TODO: localize
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
                        // TODO: localize 'Pick a date'
                        : 'Pick a date',
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
                    (val == null || val.isEmpty) ? '${field.label} is required' : null // TODO: localize
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
                    (val == null || val.isEmpty) ? '${field.label} is required' : null // TODO: localize
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
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        // TODO: localize
                        Text('No generated documents yet.',
                            style: TextStyle(color: Colors.grey)),
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
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (doc.templateName != null)
                          // TODO: localize 'Template'
                          Text('Template: ${doc.templateName}'),
                        if (doc.caseCode != null)
                          // TODO: localize 'Case'
                          Text('Case: ${doc.caseCode}'),
                        // TODO: localize 'Generated'
                        Text(
                            'Generated: ${doc.generatedAt.toLocal().toString().split('.').first}'),
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

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        // TODO: localize 'New Draft'
        title: const Text('New Draft'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleCtrl,
                // TODO: localize
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Title is required' : null, // TODO: localize
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: contentCtrl,
                // TODO: localize
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Content is required' : null, // TODO: localize
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            // TODO: localize 'Cancel'
            child: const Text('Cancel'),
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
            // TODO: localize 'Save'
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DocDraft draft) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        // TODO: localize 'Delete Draft'
        title: const Text('Delete Draft'),
        // TODO: localize confirmation message
        content: Text('Delete "${draft.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            // TODO: localize 'Cancel'
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<DocGenerationBloc>().add(DeleteDocDraft(draft.id));
              Navigator.pop(dialogCtx);
            },
            // TODO: localize 'Delete'
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
        bool isLoading = state is DocGenLoading;

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
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.drafts, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      // TODO: localize
                      Text('No drafts yet.', style: TextStyle(color: Colors.grey)),
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
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      // TODO: localize 'Created'
                      'Created: ${draft.createdAt.toLocal().toString().split('.').first}',
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
            // TODO: localize tooltip 'New Draft'
            tooltip: 'New Draft',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
