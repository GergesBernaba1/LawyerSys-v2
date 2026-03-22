import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';

import '../bloc/tasks_bloc.dart';
import '../bloc/tasks_event.dart';
import '../bloc/tasks_state.dart';
import 'task_form_screen.dart';

class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TasksBloc>().add(LoadTasks());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localizer.tasks)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: localizer.searchTasks,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => context.read<TasksBloc>().add(SearchTasks(_searchController.text)),
                ),
              ),
              onSubmitted: (v) => context.read<TasksBloc>().add(SearchTasks(v)),
            ),
          ),
          Expanded(
            child: BlocBuilder<TasksBloc, TasksState>(
              builder: (context, state) {
                if (state is TasksLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TasksError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                if (state is TasksLoaded) {
                  final tasks = state.tasks;
                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.task_alt, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(localizer.noTasksFound),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TaskFormScreen()),
                            ),
                            child: Text(localizer.createFirstTask),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return ListTile(
                        title: Text(task.taskName),
                        subtitle: Text('${task.type} • ${task.taskDate?.split('T')[0] ?? ''}'),
                        trailing: PopupMenuButton<int>(
                          onSelected: (value) async {
                            if (value == 1) {
                              // Edit
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TaskFormScreen(task: task),
                                ),
                              );
                              // Refresh after edit
                              context.read<TasksBloc>().add(LoadTasks());
                            } else if (value == 2) {
                              // Delete
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(localizer.taskDelete),
                                  content: Text('${localizer.taskDeleteAlert} "${task.taskName}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text(localizer.cancel),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: Text(localizer.taskDelete),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                context.read<TasksBloc>().add(DeleteTask(task.id ?? 0));
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem<int>(
                              value: 1,
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Edit'),
                              ),
                            ),
                            const PopupMenuItem<int>(
                              value: 2,
                              child: ListTile(
                                leading: Icon(Icons.delete),
                                title: Text('Delete'),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          // View task details (could navigate to detail screen)
                          // For now, just show a snack bar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${localizer.task}: ${task.taskName}')),
                          );
                        },
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TaskFormScreen()),
          );
          // Refresh after adding
          context.read<TasksBloc>().add(LoadTasks());
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Task',
      ),
    );
  }
}