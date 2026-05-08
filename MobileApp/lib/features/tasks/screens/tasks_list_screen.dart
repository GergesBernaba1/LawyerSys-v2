import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';

import 'package:qadaya_lawyersys/features/tasks/bloc/tasks_bloc.dart';
import 'package:qadaya_lawyersys/features/tasks/bloc/tasks_event.dart';
import 'package:qadaya_lawyersys/features/tasks/bloc/tasks_state.dart';
import 'package:qadaya_lawyersys/features/tasks/models/task.dart';
import 'package:qadaya_lawyersys/features/tasks/screens/task_form_screen.dart';

class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  final _employeeIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    context.read<TasksBloc>().add(LoadTasks());
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 0:
        context.read<TasksBloc>().add(LoadTasks());
      case 1:
        context.read<TasksBloc>().add(LoadUpcomingTasks());
    }
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _searchController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizer.tasks),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: localizer.all),
            Tab(text: localizer.upcomingTasks),
            Tab(text: localizer.tasksByEmployee),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AllTasksTab(searchController: _searchController),
          const _UpcomingTasksTab(),
          _ByEmployeeTab(employeeIdController: _employeeIdController),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const TaskFormScreen()),
          );
          if (context.mounted) context.read<TasksBloc>().add(LoadTasks());
        },
        tooltip: localizer.createTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// All Tasks tab
// ---------------------------------------------------------------------------

class _AllTasksTab extends StatelessWidget {
  const _AllTasksTab({required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: localizer.searchTasks,
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () =>
                    context.read<TasksBloc>().add(SearchTasks(searchController.text)),
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
                return Center(child: Text('${localizer.error}: ${state.message}'));
              }
              if (state is TasksLoaded) {
                return _TaskListView(tasks: state.tasks);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Upcoming Tasks tab
// ---------------------------------------------------------------------------

class _UpcomingTasksTab extends StatelessWidget {
  const _UpcomingTasksTab();

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;
    return BlocBuilder<TasksBloc, TasksState>(
      builder: (context, state) {
        if (state is TasksLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TasksError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${localizer.error}: ${state.message}'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      context.read<TasksBloc>().add(LoadUpcomingTasks()),
                  child: Text(localizer.retry),
                ),
              ],
            ),
          );
        }
        if (state is UpcomingTasksLoaded) {
          if (state.tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_available, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    localizer.noUpcomingTasks,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return _TaskListView(tasks: state.tasks);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ---------------------------------------------------------------------------
// By Employee tab
// ---------------------------------------------------------------------------

class _ByEmployeeTab extends StatelessWidget {
  const _ByEmployeeTab({required this.employeeIdController});

  final TextEditingController employeeIdController;

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: employeeIdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: localizer.selectEmployee,
                    hintText: 'ID',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final id = int.tryParse(employeeIdController.text.trim());
                  if (id != null) {
                    context.read<TasksBloc>().add(LoadTasksByEmployee(id));
                  }
                },
                child: Text(localizer.search),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: BlocBuilder<TasksBloc, TasksState>(
            builder: (context, state) {
              if (state is TasksLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is TasksError) {
                return Center(
                  child: Text('${localizer.error}: ${state.message}'),
                );
              }
              if (state is EmployeeTasksLoaded) {
                if (state.tasks.isEmpty) {
                  return Center(
                    child: Text(
                      localizer.noTasksFound,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return _TaskListView(tasks: state.tasks);
              }
              return Center(
                child: Text(
                  localizer.selectEmployee,
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared task list view
// ---------------------------------------------------------------------------

class _TaskListView extends StatelessWidget {
  const _TaskListView({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;
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
                MaterialPageRoute<void>(builder: (_) => const TaskFormScreen()),
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
          leading: const Icon(Icons.task_alt, color: Colors.indigo),
          title: Text(task.taskName),
          subtitle: Text(
            '${task.type}${task.taskDate != null ? '  ·  ${task.taskDate!.split('T')[0]}' : ''}'
            '${task.employeeName != null ? '\n${task.employeeName}' : ''}',
          ),
          isThreeLine: task.employeeName != null,
          trailing: PopupMenuButton<int>(
            onSelected: (value) async {
              if (value == 1) {
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TaskFormScreen(task: task),
                  ),
                );
                if (context.mounted) context.read<TasksBloc>().add(LoadTasks());
              } else if (value == 2) {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(localizer.taskDelete),
                    content: Text(
                        '${localizer.taskDeleteAlert} "${task.taskName}"?',),
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
                if ((confirmed ?? false) && context.mounted) {
                  context
                      .read<TasksBloc>()
                      .add(DeleteTask(task.id ?? 0));
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<int>(
                value: 1,
                child: ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text(localizer.edit),
                ),
              ),
              PopupMenuItem<int>(
                value: 2,
                child: ListTile(
                  leading: const Icon(Icons.delete),
                  title: Text(localizer.taskDelete),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
