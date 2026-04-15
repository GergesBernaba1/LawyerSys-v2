import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/localization/app_localizations.dart';
import '../../authentication/bloc/auth_bloc.dart';
import '../../authentication/bloc/auth_state.dart';
import '../../authentication/models/user_session.dart';
import '../bloc/employees_bloc.dart';
import '../bloc/employees_event.dart';
import '../bloc/employees_state.dart';
import '../models/employee.dart';

class EmployeeDetailScreen extends StatefulWidget {
  const EmployeeDetailScreen({
    super.key,
    required this.employeeModel,
  });

  final EmployeeModel employeeModel;

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _jobController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _emailController;
  late final TextEditingController _salaryController;

  bool _isEditingSalary = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.employeeModel.user?.fullName ?? '');
    _jobController =
        TextEditingController(text: widget.employeeModel.user?.job ?? '');
    _phoneNumberController = TextEditingController(
        text: widget.employeeModel.user?.phoneNumber ?? '');
    _emailController =
        TextEditingController(text: widget.employeeModel.identity?.email ?? '');
    _salaryController =
        TextEditingController(text: widget.employeeModel.salary.toString());
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _jobController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _saveSalary() {
    final localizer = AppLocalizations.of(context);
    final parsedSalary = int.tryParse(_salaryController.text.trim());

    if (parsedSalary == null || parsedSalary < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizer.allFieldsAreRequired)),
      );
      return;
    }

    setState(() => _isSaving = true);
    final updatedEmployee = EmployeeModel(
      id: widget.employeeModel.id,
      salary: parsedSalary,
      usersId: widget.employeeModel.usersId,
      user: widget.employeeModel.user,
      identity: widget.employeeModel.identity,
      profileImagePath: widget.employeeModel.profileImagePath,
      lastSyncedAt: DateTime.now(),
      isDirty: false,
    );
    context.read<EmployeesBloc>().add(UpdateEmployee(updatedEmployee));
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);
    final authState = context.watch<AuthBloc>().state;
    final session = authState is AuthAuthenticated ? authState.session : null;
    final canEditSalary =
        (session?.hasPermission(Permissions.editEmployees) ?? false) &&
        (session?.isAdmin() ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizer.employeeDetails),
        actions: [
          if (canEditSalary)
            IconButton(
              icon: Icon(_isEditingSalary ? Icons.save : Icons.edit),
              onPressed: _isSaving
                  ? null
                  : () {
                      if (_isEditingSalary) {
                        _saveSalary();
                      } else {
                        setState(() => _isEditingSalary = true);
                      }
                    },
            ),
        ],
      ),
      body: BlocListener<EmployeesBloc, EmployeesState>(
        listener: (context, state) {
          if (state is EmployeeOperationSuccess) {
            setState(() {
              _isSaving = false;
              _isEditingSalary = false;
            });
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is EmployeesError) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${localizer.error}: ${state.message}')));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Text(
                localizer.employeeInformation,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _fullNameController,
                label: localizer.fullName,
                enabled: false,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _emailController,
                label: localizer.email,
                enabled: false,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _jobController,
                label: localizer.job,
                enabled: false,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _phoneNumberController,
                label: localizer.phoneNumber,
                enabled: false,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _salaryController,
                label: localizer.salary,
                enabled: _isEditingSalary && !_isSaving,
                keyboardType: TextInputType.number,
              ),
              if (_isSaving) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      enabled: enabled,
      keyboardType: keyboardType,
    );
  }
}
