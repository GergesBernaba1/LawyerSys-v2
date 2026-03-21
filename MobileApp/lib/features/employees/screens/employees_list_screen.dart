import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/localization/app_localizations.dart';
import '../../authentication/bloc/auth_bloc.dart';
import '../../authentication/bloc/auth_state.dart';
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

  @override
  void initState() {
    super.initState();
    context.read<EmployeesBloc>().add(LoadEmployees());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);
    final authState = context.watch<AuthBloc>().state;
    final session = authState is AuthAuthenticated ? authState.session : null;

    return Scaffold(
      appBar: AppBar(title: Text(localizer.employees)),
      floatingActionButton: (session?.hasPermission(Permissions.createEmployees) ?? false)
          ? FloatingActionButton(
              onPressed: () async {
                context.read<EmployeesBloc>().add(RefreshEmployees());
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: BlocListener<EmployeesBloc, EmployeesState>(
        listener: (context, state) {
          if (state is EmployeeOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            context.read<EmployeesBloc>().add(RefreshEmployees());
          }
          if (state is EmployeesError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${localizer.error}: ${state.message}')));
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
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => context.read<EmployeesBloc>().add(SearchEmployees(_searchController.text)),
                  ),
                ),
                onSubmitted: (v) => context.read<EmployeesBloc>().add(SearchEmployees(v)),
              ),
            ),
            Expanded(
              child: BlocBuilder<EmployeesBloc, EmployeesState>(
                builder: (context, state) {
                  if (state is EmployeesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is EmployeesError) {
                    return Center(child: Text('${localizer.error}: ${state.message}'));
                  }
                  if (state is EmployeesLoaded) {
                    final employees = state.employees;
                    if (employees.isEmpty) {
                      return Center(child: Text(localizer.noEmployeesFound));
                    }
                    return ListView.builder(
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final employee = employees[index];
                        return ListTile(
                          title: Text(employee.user?.fullName ?? 'Unknown'),
                          subtitle: Text('${localizer.job}: ${employee.user?.job ?? 'N/A'} • ${localizer.department}: ${employee.user?.ssn ?? 'N/A'}'),
                          onTap: () {
                            context.read<EmployeesBloc>().add(SelectEmployee(employee.id));
                            Navigator.push(context, MaterialPageRoute(builder: (context) => EmployeeDetailScreen(employeeModel: employee)));
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
      ),
    );
  }
}