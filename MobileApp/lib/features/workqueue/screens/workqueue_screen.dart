import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/workqueue_bloc.dart';
import '../bloc/workqueue_event.dart';
import '../bloc/workqueue_state.dart';
import '../models/workqueue_task.dart';

class WorkqueueScreen extends StatefulWidget {
  const WorkqueueScreen({super.key});

  @override
  State<WorkqueueScreen> createState() => _WorkqueueScreenState();
}

class _WorkqueueScreenState extends State<WorkqueueScreen> {
  // null means "All"
  String? _selectedStatus;

  static const _filters = <String?>[null, 'Pending', 'InProgress', 'Completed'];
  static const _filterLabels = <String>['All', 'Pending', 'In Progress', 'Completed'];

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
    final controller = TextEditingController();
    final confirmed = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reassign Task'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Employee ID',
            hintText: 'Enter the target employee ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final id = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, id);
            },
            child: const Text('Reassign'),
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
      BuildContext context, WorkqueueTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark Complete'),
        content: Text('Mark "${task.title}" as complete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<WorkqueueBloc>().add(CompleteTask(task.id));
    }
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(_filters.length, (i) {
          final filterValue = _filters[i];
          final label = _filterLabels[i];
          final isSelected = _selectedStatus == filterValue;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
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
    final dueDateStr = task.dueDate != null
        ? DateFormat('MMM d, yyyy').format(task.dueDate!)
        : null;

    final subtitleParts = <String>[
      if (task.caseCode != null) 'Case: ${task.caseCode}',
      if (dueDateStr != null) 'Due: $dueDateStr',
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
                  style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusChipColor(task.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _statusChipColor(task.status).withValues(alpha: 0.5)),
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
          itemBuilder: (_) => [
            const PopupMenuItem<String>(
              value: 'in_progress',
              child: ListTile(
                leading: Icon(Icons.play_arrow),
                title: Text('Mark In Progress'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'complete',
              child: ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Mark Complete'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'reassign',
              child: ListTile(
                leading: Icon(Icons.person_add),
                title: Text('Reassign'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Workqueue'), // TODO: localize
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
                      content: Text('Error: ${state.message}'),
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
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Your workqueue is empty',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
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
                    children: const [
                      SizedBox(height: 200),
                      Center(
                        child: Text('Pull to refresh'),
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
