import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/timetracking/bloc/timetracking_bloc.dart';
import 'package:qadaya_lawyersys/features/timetracking/bloc/timetracking_event.dart';
import 'package:qadaya_lawyersys/features/timetracking/bloc/timetracking_state.dart';
import 'package:qadaya_lawyersys/features/timetracking/models/time_entry.dart';
import 'package:qadaya_lawyersys/features/timetracking/screens/timetracking_form_screen.dart';

class TimeTrackingListScreen extends StatefulWidget {
  const TimeTrackingListScreen({super.key});

  @override
  State<TimeTrackingListScreen> createState() => _TimeTrackingListScreenState();
}

class _TimeTrackingListScreenState extends State<TimeTrackingListScreen> {
  final _hourlyRateController = TextEditingController();
  final _workTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCaseCode;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    context.read<TimeTrackingBloc>().add(LoadTimeEntries());
    context.read<TimeTrackingBloc>().add(LoadSuggestions(0));
    context.read<TimeTrackingBloc>().add(LoadCaseOptions());
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    _workTypeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizer.timeTracking)),
      body: BlocBuilder<TimeTrackingBloc, TimeTrackingState>(
        builder: (context, state) {
          if (state is TimeTrackingLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TimeTrackingError) {
            return Center(child: Text('${localizer.error}: ${state.message}'));
          }
          if (state is TimeTrackingLoaded) {
            final entries = state.entries;
            final suggestions = state.suggestions;
            final caseOptions = state.caseOptions;
            final hourlyRate = state.hourlyRate;

            if (entries.isEmpty && suggestions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(localizer.noTimeEntriesFound),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TimeTrackingFormScreen()),
                      ),
                      child: Text(localizer.startTrackingTime),
                    ),
                  ],
                ),
              );
            }

            final runningEntries = entries.where((x) => _statusCode(x.status, localizer) == 'Running').toList();
            final stoppedEntries = entries.where((x) => _statusCode(x.status, localizer) == 'Stopped').toList();
            final totalTrackedMinutes = stoppedEntries.fold<int>(
                0, (sum, entry) => sum + (entry.durationMinutes ?? 0),);

            return ListView(
              children: [
                // Summary cards
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                            localizer.runningStatus, runningEntries.length, Colors.orange,),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                            localizer.stoppedStatus, stoppedEntries.length, Colors.green,),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                            localizer.duration, totalTrackedMinutes, Colors.blue,),
                      ),
                    ],
                  ),
                ),

                // Start time tracking form
                _buildStartForm(context, caseOptions, hourlyRate),

                // Running entries notice
                if (runningEntries.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.amber[50],
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${runningEntries.length} ${localizer.runningStatus}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Filter to show only running
                          },
                          child: Text(localizer.viewRunningTimers),
                        ),
                      ],
                    ),
                  ),

                // Entries table
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    localizer.timeEntries,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildEntriesTable(entries),

                // Suggestions table
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    localizer.suggestions,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildSuggestionsTable(suggestions),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TimeTrackingFormScreen()),
        ),
        tooltip: localizer.startTrackingTime,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(String label, dynamic value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartForm(
      BuildContext context, List<Map<String, dynamic>> caseOptions, double hourlyRate,) {
    final localizer = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizer.startTrackingTime,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCaseCode,
                    decoration: InputDecoration(
                      labelText: localizer.caseCode,
                      border: const OutlineInputBorder(),
                    ),
                    items: caseOptions
                        .map((option) => DropdownMenuItem<String>(
                              value: option['value'].toString(),
                              child: Text(option['label'] as String),
                            ),)
                        .toList()
                        ..insert(
                            0,
                            DropdownMenuItem<String>(
                              value: '',
                              child: Text(localizer.selectACase),
                            ),),
                    onChanged: (value) {
                      setState(() {
                        _selectedCaseCode = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _workTypeController,
                    decoration: InputDecoration(
                      labelText: localizer.workTypeLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: localizer.description,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hourlyRateController,
                    decoration: InputDecoration(
                      labelText: localizer.hourlyRate,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _statusFilter,
                    decoration: InputDecoration(
                      labelText: localizer.statusLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'All',
                        child: Text(localizer.all),
                      ),
                      DropdownMenuItem(
                        value: 'Running',
                        child: Text(localizer.running),
                      ),
                      DropdownMenuItem(
                        value: 'Stopped',
                        child: Text(localizer.stopped),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value!;
                      });
                      context
                          .read<TimeTrackingBloc>()
                          .add(LoadTimeEntries(statusFilter: value));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedCaseCode == null || _selectedCaseCode!.isEmpty
                      ? null
                      : () {
                          context.read<TimeTrackingBloc>().add(StartTimeEntry(
                                caseCode: int.tryParse(_selectedCaseCode!),
                                workType: _workTypeController.text,
                                description: _descriptionController.text,
                                hourlyRate: double.tryParse(
                                        _hourlyRateController.text,) ?? 0,
                                statusFilter: _statusFilter,
                              ),);
                          // Clear form
                          _workTypeController.clear();
                          _descriptionController.clear();
                          _hourlyRateController.clear();
                        },
                  child: Text(localizer.start),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesTable(List<TimeEntry> entries) {
    final localizer = AppLocalizations.of(context)!;

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Center(child: Text(localizer.noTimeEntriesFound)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(localizer.workTypeLabel)),
          DataColumn(label: Text(localizer.status)),
          DataColumn(label: Text(localizer.duration)),
          DataColumn(label: Text(localizer.amount)),
          DataColumn(label: Text(localizer.actions)),
        ],
        rows: entries
            .map((entry) => DataRow(cells: [
                  DataCell(Text('${entry.workType} ${entry.description ?? ''}')),
                  DataCell(Chip(
                    label: Text(_localizedStatusLabel(entry.status, localizer)),
                    backgroundColor: _statusCode(entry.status, localizer) == 'Running'
                        ? Colors.orange[100]
                        : Colors.green[100],
                  ),),
                  DataCell(Text('${entry.durationMinutes ?? 0} min')),
                  DataCell(Text(
                      '\$${(entry.suggestedAmount ?? 0).toStringAsFixed(2)}',),),
                  DataCell(_statusCode(entry.status, localizer) == 'Running'
                      ? IconButton(
                          icon: const Icon(Icons.stop),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(localizer.stopTimerFunctionality)),
                            );
                          },
                        )
                      : const Text(''),),
                ],),)
            .toList(),
      ),
    );
  }

  String _statusCode(String status, AppLocalizations localizer) {
    final normalized = status.trim();
    if (normalized.toLowerCase() == 'running' || normalized == localizer.running) {
      return 'Running';
    }
    if (normalized.toLowerCase() == 'stopped' || normalized == localizer.stopped) {
      return 'Stopped';
    }
    if (normalized.toLowerCase() == 'all' || normalized == localizer.all) {
      return 'All';
    }
    return normalized;
  }

  String _localizedStatusLabel(String status, AppLocalizations localizer) {
    switch (_statusCode(status, localizer)) {
      case 'Running':
        return localizer.running;
      case 'Stopped':
        return localizer.stopped;
      case 'All':
        return localizer.all;
      default:
        return status;
    }
  }

  Widget _buildSuggestionsTable(List<Suggestion> suggestions) {
    final localizer = AppLocalizations.of(context)!;
    if (suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Center(child: Text(localizer.noSuggestions)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(localizer.dataColumnCase)),
          DataColumn(label: Text(localizer.dataColumnCustomer)),
          DataColumn(label: Text(localizer.dataColumnMinutes)),
          DataColumn(label: Text(localizer.dataColumnAmount)),
        ],
        rows: suggestions
            .map((suggestion) => DataRow(cells: [
                  DataCell(Text('${suggestion.caseCode ?? '-'}')),
                  DataCell(Text('${suggestion.customerId ?? '-'}')),
                  DataCell(Text('${suggestion.totalMinutes}')),
                  DataCell(Text('\$${suggestion.suggestedAmount.toStringAsFixed(2)}')),
                ],),)
            .toList(),
      ),
    );
  }
}
