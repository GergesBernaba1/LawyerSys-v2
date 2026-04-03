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
  late final TextEditingController _ssnController;
  late final TextEditingController _addressController;
  late final TextEditingController _salaryController;

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.employeeModel.user?.fullName ?? '');
    _jobController =
        TextEditingController(text: widget.employeeModel.user?.job ?? '');
    _phoneNumberController = TextEditingController(
        text: widget.employeeModel.user?.phoneNumber ?? '');
    _ssnController =
        TextEditingController(text: widget.employeeModel.user?.ssn ?? '');
    _addressController =
        TextEditingController(text: widget.employeeModel.user?.address ?? '');
    _salaryController =
        TextEditingController(text: widget.employeeModel.salary.toString());
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _jobController.dispose();
    _phoneNumberController.dispose();
    _ssnController.dispose();
    _addressController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _saveEmployee() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final updatedEmployee = EmployeeModel(
        id: widget.employeeModel.id,
        salary:
            int.tryParse(_salaryController.text) ?? widget.employeeModel.salary,
        usersId: widget.employeeModel.usersId,
        user: UserModel(
          id: widget.employeeModel.user?.id ?? 0,
          fullName: _fullNameController.text,
          address:
              _addressController.text.isEmpty ? null : _addressController.text,
          job: _jobController.text,
          phoneNumber: _phoneNumberController.text,
          dateOfBirth: widget.employeeModel.user?.dateOfBirth,
          ssn: _ssnController.text,
          userName: widget.employeeModel.user?.userName ?? '',
          profileImagePath: widget.employeeModel.user?.profileImagePath,
        ),
        identity: widget.employeeModel.identity,
        profileImagePath: widget.employeeModel.profileImagePath,
        lastSyncedAt: DateTime.now(),
        isDirty: true,
      );
      context.read<EmployeesBloc>().add(UpdateEmployee(updatedEmployee));
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);
    final authState = context.watch<AuthBloc>().state;
    final session = authState is AuthAuthenticated ? authState.session : null;
    final canEdit = session?.hasPermission(Permissions.editEmployees) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizer.employeeDetails),
        actions: [
          if (canEdit)
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() => _isEditing = !_isEditing);
                      if (!_isEditing) {
                        _saveEmployee();
                      }
                    },
            ),
        ],
      ),
      body: BlocConsumer<EmployeesBloc, EmployeesState>(
        listener: (context, state) {
          if (state is EmployeeOperationSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is EmployeesError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${localizer.error}: ${state.message}')));
          }
        },
        builder: (context, state) {
          if (state is EmployeesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EmployeesError) {
            return Center(child: Text('${localizer.error}: ${state.message}'));
          }

          return Padding(
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
                  enabled: _isEditing,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _jobController,
                  label: localizer.job,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _phoneNumberController,
                  label: localizer.phoneNumber,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _ssnController,
                  label: localizer.ssn,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _addressController,
                  label: localizer.address,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _salaryController,
                  label: localizer.salary,
                  enabled: _isEditing,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                if (!_isEditing) ...[
                  Text(
                    '${localizer.lastSyncedAt}: ${widget.employeeModel.lastSyncedAt?.toString() ?? localizer.never}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizer.isDirty}: ${widget.employeeModel.isDirty ? localizer.yes : localizer.no}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          );
        },
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
