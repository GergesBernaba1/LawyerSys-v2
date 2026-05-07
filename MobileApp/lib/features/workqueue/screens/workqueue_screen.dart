import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';

import 'package:qadaya_lawyersys/features/workqueue/bloc/workqueue_bloc.dart';
import 'package:qadaya_lawyersys/features/workqueue/bloc/workqueue_event.dart';
import 'package:qadaya_lawyersys/features/workqueue/bloc/workqueue_state.dart';
import 'package:qadaya_lawyersys/features/workqueue/models/workqueue_task.dart';

class WorkqueueScreen extends StatefulWidget {
  const WorkqueueScreen({super.key});

  @override
  State<WorkqueueScreen> createState() => _WorkqueueScreenState();
}

class _WorkqueueScreenState extends State<WorkqueueScreen> {
  // null means "All"
  String? _selectedStatus;

  static const _filters = <String?>[null, 'Pending', 'InProgress', 'Completed'];

  @override
  void initState() {
    super.initState();
    context.read<WorkqueueBloc>().add(LoadWorkqueue(status: _selectedStatus));
  }

  void _applyFilter(String? status) {
    setState(() => _selectedStatus = status);
    context.read<WorkqueueBloc>().add(LoadWorkqueue(status: status));
  }

  Color _priorityColor(String? priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _statusChipColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'InProgress':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showReassignDialog(BuildContext context, WorkqueueTask task) async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final confirmed = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.reassignTask),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l.employeeIdLabel,
            hintText: l.enterTargetEmployeeId,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final id = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, id);
            },
            child: Text(l.reassignTask),
          ),
        ],
      ),
    );
    controller.dispose();
    if (confirmed != null && context.mounted) {
      context.read<WorkqueueBloc>().add(ReassignTask(task.id, confirmed));
    }
  }

  Future<void> _showCompleteConfirmDialog(
      BuildContext context, WorkqueueTask task,) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.markComplete),
        content: Text(l.markCompletePrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.markComplete),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && context.mounted) {
      context.read<WorkqueueBloc>().add(CompleteTask(task.id));
    }
  }

  Widget _buildFilterChips() {
    final l = AppLocalizations.of(context)!;
    final filterLabels = <String>[
      l.all,
      l.statusPending,
      l.statusInProgress,
      l.statusCompleted,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(_filters.length, (i) {
          final filterValue = _filters[i];
          final label = filterLabels[i];
          final isSelected = _selectedStatus == filterValue;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => _applyFilter(filterValue),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTaskTile(BuildContext context, WorkqueueTask task) {
    final locale = Localizations.localeOf(context).languageCode;
    final dueDateStr = task.dueDate != null
        ? DateFormat('MMM d, yyyy', locale).format(task.dueDate!)
        : null;

    final l = AppLocalizations.of(context)!;
    final subtitleParts = <String>[
      if (task.caseCode != null) '${l.caseNumber}: ${task.caseCode}',
      if (dueDateStr != null) '${l.reminderDate}: $dueDateStr',
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 8,
          backgroundColor: _priorityColor(task.priority),
        ),
        title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitleParts.isNotEmpty)
              Text(subtitleParts.join(' · '),
                  style: const TextStyle(fontSize: 12),),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusChipColor(task.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _statusChipColor(task.status).withValues(alpha: 0.5),),
              ),
              child: Text(
                task.status,
                style: TextStyle(
                  fontSize: 11,
                  color: _statusChipColor(task.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'in_progress') {
              context
                  .read<WorkqueueBloc>()
                  .add(UpdateTaskStatus(task.id, 'InProgress'));
            } else if (value == 'complete') {
              await _showCompleteConfirmDialog(context, task);
            } else if (value == 'reassign') {
              await _showReassignDialog(context, task);
            }
          },
          itemBuilder: (menuContext) {
            final l = AppLocalizations.of(menuContext)!;
            return [
              PopupMenuItem<String>(
                value: 'in_progress',
                child: ListTile(
                  leading: const Icon(Icons.play_arrow),
                  title: Text(l.markInProgress),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'complete',
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(l.markComplete),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'reassign',
                child: ListTile(
                  leading: const Icon(Icons.person_add),
                  title: Text(l.reassignTask),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ];
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myWorkqueue),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: BlocConsumer<WorkqueueBloc, WorkqueueState>(
              listener: (context, state) {
                if (state is WorkqueueTaskUpdated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                } else if (state is WorkqueueError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.error}: ${state.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is WorkqueueLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is WorkqueueLoaded) {
                  final tasks = state.tasks;
                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            l10n.workqueueEmpty,
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<WorkqueueBloc>().add(RefreshWorkqueue());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) =>
                          _buildTaskTile(context, tasks[index]),
                    ),
                  );
                }

                // WorkqueueInitial / WorkqueueError (non-loaded states)
                return RefreshIndicator(
                  onRefresh: () async {
                    context
                        .read<WorkqueueBloc>()
                        .add(LoadWorkqueue(status: _selectedStatus));
                  },
                  child: ListView(
                    children: [
                      const SizedBox(height: 200),
                      Center(
                        child: Text(l10n.refresh),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
