import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/court_automation_bloc.dart';
import '../bloc/court_automation_event.dart';
import '../bloc/court_automation_state.dart';
import '../models/court_automation_models.dart';

class CourtAutomationScreen extends StatefulWidget {
  const CourtAutomationScreen({super.key});

  @override
  State<CourtAutomationScreen> createState() => _CourtAutomationScreenState();
}

class _CourtAutomationScreenState extends State<CourtAutomationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<CourtAutomationBloc>().add(LoadAutomationPacks());

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 1) {
          context.read<CourtAutomationBloc>().add(LoadFilings());
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
        // TODO: localize 'Court Automation'
        title: const Text('Court Automation'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            // TODO: localize tab labels
            Tab(text: 'Filing Packs'),
            Tab(text: 'My Filings'),
          ],
        ),
      ),
      body: BlocListener<CourtAutomationBloc, CourtAutoState>(
        listener: (context, state) {
          if (state is CourtAutoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              // TODO: localize 'Error'
              SnackBar(content: Text('Error: ${state.message}')),
            );
          } else if (state is FilingSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              // TODO: localize
              SnackBar(
                  content: Text(
                      'Filing submitted! ID: ${state.submission.submissionId}')),
            );
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: const [
            _PacksTab(),
            _FilingsTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — Filing Packs
// ---------------------------------------------------------------------------

class _PacksTab extends StatelessWidget {
  const _PacksTab();

  void _openPackSheet(BuildContext context, AutomationPack pack) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<CourtAutomationBloc>(),
        child: _PackBottomSheet(pack: pack),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourtAutomationBloc, CourtAutoState>(
      builder: (context, state) {
        if (state is CourtAutoLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<AutomationPack> packs = [];
        if (state is AutomationPacksLoaded) {
          packs = state.packs;
        }

        if (packs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gavel, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                // TODO: localize
                const Text('No automation packs available.',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context
                      .read<CourtAutomationBloc>()
                      .add(LoadAutomationPacks()),
                  // TODO: localize 'Retry'
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: packs.length,
          itemBuilder: (context, index) {
            final pack = packs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openPackSheet(context, pack),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.folder_special, color: Colors.indigo),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              pack.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (pack.category != null)
                            Chip(
                              label: Text(
                                pack.category!,
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor:
                                  Colors.indigo.withValues(alpha: 0.15),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      if (pack.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          pack.description!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // TODO: localize 'Tap to open'
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Tap to open',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 12)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios,
                              size: 12,
                              color: Theme.of(context).primaryColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Sheet — Pack Details, Deadlines, Submit
// ---------------------------------------------------------------------------

class _PackBottomSheet extends StatefulWidget {
  final AutomationPack pack;
  const _PackBottomSheet({required this.pack});

  @override
  State<_PackBottomSheet> createState() => _PackBottomSheetState();
}

class _PackBottomSheetState extends State<_PackBottomSheet> {
  final _caseCodeCtrl = TextEditingController();
  DateTime? _filingDate;
  List<DeadlineItem> _deadlines = [];
  bool _deadlinesLoaded = false;

  @override
  void dispose() {
    _caseCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFilingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filingDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _filingDate = picked;
        _deadlines = [];
        _deadlinesLoaded = false;
      });
    }
  }

  void _calculateDeadlines() {
    if (_filingDate == null) return;
    context.read<CourtAutomationBloc>().add(
          CalculateDeadlines(
            packKey: widget.pack.packKey,
            filingDate:
                _filingDate!.toIso8601String().split('T').first,
          ),
        );
  }

  void _showSubmitDialog() {
    if (_caseCodeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        // TODO: localize
        const SnackBar(content: Text('Please enter a case code first.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        // TODO: localize 'Submit Filing'
        title: const Text('Submit Filing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODO: localize 'Confirm submission for case:'
            const Text('Confirm submission for case:'),
            const SizedBox(height: 4),
            Text(
              _caseCodeCtrl.text.trim(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            // TODO: localize 'Pack:'
            Text('Pack: ${widget.pack.name}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            // TODO: localize 'Cancel'
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CourtAutomationBloc>().add(
                    SubmitFiling(
                      caseCode: _caseCodeCtrl.text.trim(),
                      packKey: widget.pack.packKey,
                      formData: {
                        if (_filingDate != null)
                          'filingDate':
                              _filingDate!.toIso8601String().split('T').first,
                      },
                    ),
                  );
              Navigator.pop(dialogCtx);
              Navigator.pop(context); // close sheet
            },
            // TODO: localize 'Submit'
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CourtAutomationBloc, CourtAutoState>(
      listener: (context, state) {
        if (state is DeadlinesCalculated &&
            state.packKey == widget.pack.packKey) {
          setState(() {
            _deadlines = state.deadlines;
            _deadlinesLoaded = true;
          });
        }
        if (state is CourtAutoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            // TODO: localize 'Error'
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          return BlocBuilder<CourtAutomationBloc, CourtAutoState>(
            builder: (context, state) {
              final isLoading = state is CourtAutoLoading;

              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Pack header
                  Row(
                    children: [
                      const Icon(Icons.folder_special,
                          color: Colors.indigo, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.pack.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (widget.pack.category != null) ...[
                    const SizedBox(height: 6),
                    Chip(
                      label: Text(widget.pack.category!),
                      backgroundColor:
                          Colors.indigo.withValues(alpha: 0.15),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                  if (widget.pack.description != null) ...[
                    const SizedBox(height: 8),
                    Text(widget.pack.description!,
                        style: TextStyle(color: Colors.grey[700])),
                  ],

                  const Divider(height: 32),

                  // Case code field
                  TextField(
                    controller: _caseCodeCtrl,
                    // TODO: localize
                    decoration: const InputDecoration(
                      labelText: 'Case Code',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.folder_open),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filing date picker
                  InkWell(
                    onTap: _pickFilingDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        // TODO: localize 'Filing Date'
                        labelText: 'Filing Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _filingDate != null
                            ? _filingDate!
                                .toLocal()
                                .toString()
                                .split(' ')
                                .first
                            // TODO: localize 'Select a date'
                            : 'Select a date',
                        style: TextStyle(
                            color: _filingDate != null ? null : Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Calculate Deadlines button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          (_filingDate == null || isLoading)
                              ? null
                              : _calculateDeadlines,
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.calculate),
                      // TODO: localize 'Calculate Deadlines'
                      label: const Text('Calculate Deadlines'),
                    ),
                  ),

                  // Deadlines list
                  if (_deadlinesLoaded && _deadlines.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    // TODO: localize 'Deadlines'
                    const Text('Deadlines',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._deadlines.map((item) => Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            leading: const Icon(Icons.event,
                                color: Colors.orange),
                            title: Text(item.label),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.deadline != null)
                                  Text(
                                    // TODO: localize 'Due'
                                    'Due: ${item.deadline}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                if (item.description != null)
                                  Text(item.description!),
                              ],
                            ),
                          ),
                        )),
                  ],

                  if (_deadlinesLoaded && _deadlines.isEmpty) ...[
                    const SizedBox(height: 12),
                    // TODO: localize
                    const Text('No deadlines returned.',
                        style: TextStyle(color: Colors.grey)),
                  ],

                  const SizedBox(height: 24),

                  // Submit Filing button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _showSubmitDialog,
                      icon: const Icon(Icons.send),
                      // TODO: localize 'Submit Filing'
                      label: const Text('Submit Filing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 — My Filings
// ---------------------------------------------------------------------------

class _FilingsTab extends StatelessWidget {
  const _FilingsTab();

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
      case 'success':
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'rejected':
      case 'failed':
      case 'error':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourtAutomationBloc, CourtAutoState>(
      builder: (context, state) {
        if (state is CourtAutoLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<FilingSubmission> filings = [];
        if (state is FilingsLoaded) {
          filings = state.filings;
        }

        if (filings.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<CourtAutomationBloc>().add(LoadFilings()),
            child: ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      // TODO: localize
                      Text('No filings yet.',
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
              context.read<CourtAutomationBloc>().add(LoadFilings()),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filings.length,
            itemBuilder: (context, index) {
              final filing = filings[index];
              final statusColor = _statusColor(filing.status);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.gavel, color: Colors.indigo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    // TODO: localize 'Case'
                                    'Case: ${filing.caseCode}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: statusColor.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    filing.status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // TODO: localize 'Pack'
                            Text('Pack: ${filing.packKey}',
                                style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(height: 2),
                            // TODO: localize 'Submitted'
                            Text(
                              'Submitted: ${filing.submittedAt.toLocal().toString().split('.').first}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
