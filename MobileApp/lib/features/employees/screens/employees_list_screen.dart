import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/skeleton_loader.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/localization/app_localizations.dart';
import '../../authentication/bloc/auth_bloc.dart';
import '../../authentication/bloc/auth_state.dart';
import '../../authentication/models/user_session.dart';
import '../../users/repositories/users_repository.dart';
import '../bloc/employees_bloc.dart';
import '../bloc/employees_event.dart';
import '../bloc/employees_state.dart';
import '../models/employee.dart';
import 'employee_detail_screen.dart';

class EmployeesListScreen extends StatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  State<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  int? _selectedUserId;
  String _createSalary = '';
  bool _isLoadingUsers = false;
  bool _isCreatingEmployee = false;

  @override
  void initState() {
    super.initState();
    context.read<EmployeesBloc>().add(LoadEmployees());
  }

  Future<void> _loadUsers() async {
    if (_users.isNotEmpty) return;
    final usersRepository = RepositoryProvider.of<UsersRepository>(context);
    setState(() => _isLoadingUsers = true);
    try {
      final users = await usersRepository.getUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _users = [];
      });
    }
    if (!mounted) return;
    setState(() => _isLoadingUsers = false);
  }

  Future<void> _showCreateEmployeeDialog() async {
    await _loadUsers();
    if (!mounted) return;

    setState(() {
      _selectedUserId = null;
      _createSalary = '';
    });

    final localizer = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${localizer.employees} - ${localizer.create}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoadingUsers)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                DropdownButtonFormField<int>(
                  initialValue: _selectedUserId,
                  decoration: InputDecoration(
                    labelText: localizer.employee,
                  ),
                  items: _users
                      .map((user) => DropdownMenuItem<int>(
                            value: int.tryParse('${user['id']}'),
                            child: Text(
                                '${user['fullName'] ?? user['email'] ?? user['userName'] ?? 'User'}'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUserId = value;
                    });
                  },
                ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: localizer.salary,
                ),
                onChanged: (value) => setState(() {
                  _createSalary = value;
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(localizer.cancel),
            ),
            TextButton(
              onPressed: _selectedUserId == null ||
                      _createSalary.trim().isEmpty ||
                      _isCreatingEmployee
                  ? null
                  : () async {
                      Navigator.of(dialogContext).pop();
                      if (!mounted) return;
                      await _createEmployee();
                    },
              child: _isCreatingEmployee
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(localizer.create),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createEmployee() async {
    final localizer = AppLocalizations.of(context)!;
    final parsedSalary = int.tryParse(_createSalary.trim());
    if (parsedSalary == null || parsedSalary < 0 || _selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizer.allFieldsAreRequired)),
      );
      return;
    }

    setState(() => _isCreatingEmployee = true);
    try {
      final employee = EmployeeModel(
        id: 0,
        usersId: _selectedUserId!,
        salary: parsedSalary,
      );
      context.read<EmployeesBloc>().add(CreateEmployee(employee));
    } finally {
      setState(() => _isCreatingEmployee = false);
    }
  }

  Future<void> _confirmDeleteEmployee(int employeeId) async {
    final localizer = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(localizer.deleteTask),
        content: Text(localizer.deleteTaskConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(localizer.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(localizer.deleteTask),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (shouldDelete == true) {
      context.read<EmployeesBloc>().add(DeleteEmployee(employeeId));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final session = authState is AuthAuthenticated ? authState.session : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizer.employees),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: localizer.refresh,
            onPressed: () {
              context.read<EmployeesBloc>().add(RefreshEmployees());
            },
          ),
        ],
      ),
      floatingActionButton:
          (session?.hasPermission(Permissions.createEmployees) ?? false) &&
                  (session?.isAdmin() ?? false)
              ? FloatingActionButton(
                  onPressed: _showCreateEmployeeDialog,
                  tooltip: localizer.create,
                  child: const Icon(Icons.add),
                )
              : null,
      body: BlocListener<EmployeesBloc, EmployeesState>(
        listener: (context, state) {
          if (state is EmployeeOperationSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
            context.read<EmployeesBloc>().add(RefreshEmployees());
          }
          if (state is EmployeesError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${localizer.error}: ${state.message}')));
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: localizer.searchEmployees,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            context.read<EmployeesBloc>().add(LoadEmployees());
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => context
                            .read<EmployeesBloc>()
                            .add(SearchEmployees(_searchController.text)),
                      ),
                    ],
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (v) =>
                    context.read<EmployeesBloc>().add(SearchEmployees(v)),
              ),
            ),
            Expanded(
              child: BlocBuilder<EmployeesBloc, EmployeesState>(
                builder: (context, state) {
                  if (state is EmployeesLoading) {
                    return const ListSkeleton(itemCount: 7);
                  }
                  if (state is EmployeesError) {
                    return Center(
                        child: Text('${localizer.error}: ${state.message}'));
                  }
                  if (state is EmployeesLoaded) {
                    final employees = state.employees;
                    if (employees.isEmpty) {
                      return Center(child: Text(localizer.noEmployeesFound));
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<EmployeesBloc>().add(RefreshEmployees());
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: employees.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final employee = employees[index];
                          final fullName = employee.user?.fullName.isNotEmpty ==
                                  true
                              ? employee.user!.fullName
                              : (employee.identity?.fullName.isNotEmpty == true
                                  ? employee.identity!.fullName
                                  : (employee.identity?.email ?? 'Unknown'));
                          final email = employee.identity?.email ?? '';
                          final job = employee.user?.job ?? '';

                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                fullName.isNotEmpty
                                    ? fullName[0].toUpperCase()
                                    : 'U',
                              ),
                            ),
                            title: Text(fullName),
                            subtitle: Text(
                              [
                                if (job.isNotEmpty) '${localizer.job}: $job',
                                if (email.isNotEmpty) email,
                              ].join(' - '),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  employee.salary.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                if ((session?.hasPermission(
                                            Permissions.editEmployees) ??
                                        false) &&
                                    (session?.isAdmin() ?? false)) ...[
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      context
                                          .read<EmployeesBloc>()
                                          .add(SelectEmployee(employee.id));
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EmployeeDetailScreen(
                                                  employeeModel: employee),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () =>
                                        _confirmDeleteEmployee(employee.id),
                                  ),
                                ],
                              ],
                            ),
                            onTap: () {
                              context
                                  .read<EmployeesBloc>()
                                  .add(SelectEmployee(employee.id));
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EmployeeDetailScreen(
                                      employeeModel: employee),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
