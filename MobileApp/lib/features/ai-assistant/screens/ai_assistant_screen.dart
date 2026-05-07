import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ignore: unused_import
import '../../../core/localization/app_localizations.dart';
import '../bloc/ai_assistant_bloc.dart';
import '../bloc/ai_assistant_event.dart';
import '../bloc/ai_assistant_state.dart';
import '../models/ai_models.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2 && !_tabController.indexIsChanging) {
        context.read<AiAssistantBloc>().add(LoadDeadlineSuggestions());
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiAssistant),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.summarize),
            Tab(text: l10n.draft),
            Tab(text: l10n.deadlines),
          ],
        ),
      ),
      body: BlocConsumer<AiAssistantBloc, AiAssistantState>(
        listener: (context, state) {
          if (state is AiAssistantError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${AppLocalizations.of(context)!.error}: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return TabBarView(
            controller: _tabController,
            children: [
              _SummarizeTab(state: state),
              _DraftTab(state: state),
              _DeadlinesTab(state: state),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summarize Tab
// ---------------------------------------------------------------------------
class _SummarizeTab extends StatefulWidget {
  final AiAssistantState state;
  const _SummarizeTab({required this.state});

  @override
  State<_SummarizeTab> createState() => _SummarizeTabState();
}

class _SummarizeTabState extends State<_SummarizeTab> {
  final _textController = TextEditingController();
  String _selectedLanguage = 'English';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.state is AiAssistantLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _textController,
            maxLines: 6,
            decoration: const InputDecoration(
              // TODO: localize 'Enter text to summarize...'
              hintText: 'Enter text to summarize...',
              // TODO: localize 'Text'
              labelText: 'Text',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedLanguage,
            // TODO: localize 'Language'
            decoration: const InputDecoration(
              labelText: 'Language',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'English', child: Text('English')),
              DropdownMenuItem(value: 'Arabic', child: Text('Arabic')),
            ],
            onChanged: (v) => setState(() => _selectedLanguage = v!),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: isLoading
                ? null
                : () {
                    final text = _textController.text.trim();
                    if (text.isEmpty) return;
                    context.read<AiAssistantBloc>().add(
                          SummarizeText(
                            text,
                            language: _selectedLanguage,
                          ),
                        );
                  },
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            // TODO: localize 'Summarize'
            label: const Text('Summarize'),
          ),
          if (widget.state is AiSummaryLoaded) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TODO: localize 'Summary'
                    Text(
                      'Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Divider(),
                    Text((widget.state as AiSummaryLoaded).summary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Draft Tab
// ---------------------------------------------------------------------------
class _DraftTab extends StatefulWidget {
  final AiAssistantState state;
  const _DraftTab({required this.state});

  @override
  State<_DraftTab> createState() => _DraftTabState();
}

class _DraftTabState extends State<_DraftTab> {
  final _promptController = TextEditingController();
  final _documentTypeController = TextEditingController();
  String _selectedLanguage = 'English';

  @override
  void dispose() {
    _promptController.dispose();
    _documentTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.state is AiAssistantLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _promptController,
            maxLines: 4,
            decoration: const InputDecoration(
              // TODO: localize 'Describe the document you want to draft...'
              hintText: 'Describe the document you want to draft...',
              // TODO: localize 'Prompt'
              labelText: 'Prompt',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _documentTypeController,
            decoration: const InputDecoration(
              // TODO: localize 'e.g. Contract, Letter, Motion...'
              hintText: 'e.g. Contract, Letter, Motion...',
              // TODO: localize 'Document Type (optional)'
              labelText: 'Document Type (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedLanguage,
            // TODO: localize 'Language'
            decoration: const InputDecoration(
              labelText: 'Language',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'English', child: Text('English')),
              DropdownMenuItem(value: 'Arabic', child: Text('Arabic')),
            ],
            onChanged: (v) => setState(() => _selectedLanguage = v!),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: isLoading
                ? null
                : () {
                    final prompt = _promptController.text.trim();
                    if (prompt.isEmpty) return;
                    final docType = _documentTypeController.text.trim();
                    context.read<AiAssistantBloc>().add(
                          DraftDocument(
                            prompt,
                            documentType: docType.isEmpty ? null : docType,
                            language: _selectedLanguage,
                          ),
                        );
                  },
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.edit_document),
            // TODO: localize 'Generate Draft'
            label: const Text('Generate Draft'),
          ),
          if (widget.state is AiDraftLoaded) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // TODO: localize 'Draft'
                              Text(
                                'Draft',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if ((widget.state as AiDraftLoaded).documentType !=
                                  null)
                                Text(
                                  (widget.state as AiDraftLoaded).documentType!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          // TODO: localize 'Copy to clipboard'
                          tooltip: 'Copy to clipboard',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                              text: (widget.state as AiDraftLoaded).content,
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              // TODO: localize 'Copied to clipboard'
                              const SnackBar(
                                  content: Text('Copied to clipboard')),
                            );
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    Text((widget.state as AiDraftLoaded).content),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Deadlines Tab
// ---------------------------------------------------------------------------
class _DeadlinesTab extends StatefulWidget {
  final AiAssistantState state;
  const _DeadlinesTab({required this.state});

  @override
  State<_DeadlinesTab> createState() => _DeadlinesTabState();
}

class _DeadlinesTabState extends State<_DeadlinesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiAssistantBloc>().add(LoadDeadlineSuggestions());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state is AiAssistantLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is AiDeadlineSuggestionsLoaded) {
      final suggestions = state.suggestions;
      if (suggestions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              // TODO: localize 'No deadline suggestions available'
              const Text('No deadline suggestions available'),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return _DeadlineSuggestionCard(suggestion: suggestions[index]);
        },
      );
    }

    // Initial state — show a load button (tab listener auto-triggers on first switch)
    return Center(
      child: ElevatedButton.icon(
        onPressed: () =>
            context.read<AiAssistantBloc>().add(LoadDeadlineSuggestions()),
        icon: const Icon(Icons.refresh),
        // TODO: localize 'Load Suggestions'
        label: const Text('Load Suggestions'),
      ),
    );
  }
}

class _DeadlineSuggestionCard extends StatelessWidget {
  final AiDeadlineSuggestion suggestion;
  const _DeadlineSuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              suggestion.taskName,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (suggestion.suggestedDeadline != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.event, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  // TODO: localize 'Suggested:'
                  Text(
                    'Suggested: ${suggestion.suggestedDeadline}',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ],
            if (suggestion.reason != null) ...[
              const SizedBox(height: 4),
              Text(
                suggestion.reason!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
