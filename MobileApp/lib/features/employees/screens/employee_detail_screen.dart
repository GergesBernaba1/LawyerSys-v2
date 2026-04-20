import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/localization/app_localizations.dart';
import '../../authentication/bloc/auth_bloc.dart';
import '../../authentication/bloc/auth_state.dart';
import '../../authentication/models/user_session.dart';
import '../../workqueue/models/workqueue_task.dart';
import '../../workqueue/repositories/workqueue_repository.dart';
import '../bloc/employees_bloc.dart';
import '../bloc/employees_event.dart';
import '../bloc/employees_state.dart';
import '../models/employee.dart';
import '../repositories/employees_repository.dart';

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
  bool _isUploadingImage = false;
  late final Future<List<WorkqueueTask>> _tasksFuture;

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
    _tasksFuture = WorkqueueRepository(ApiClient())
        .getTasksByEmployee(widget.employeeModel.usersId);
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

  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;

    setState(() => _isUploadingImage = true);
    try {
      final repo = RepositoryProvider.of<EmployeesRepository>(context);
      await repo.uploadProfileImage(widget.employeeModel.id, picked.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _saveSalary() {
    final localizer = AppLocalizations.of(context)!;
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
    final localizer = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final session = authState is AuthAuthenticated ? authState.session : null;
    final canEditSalary =
        (session?.hasPermission(Permissions.editEmployees) ?? false) &&
        (session?.isAdmin() ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizer.employeeDetails),
        actions: [
          if (_isUploadingImage)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.add_a_photo),
              tooltip: 'Upload Profile Photo',
              onPressed: _uploadProfileImage,
            ),
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
              const SizedBox(height: 24),
              Text(
                'Assigned Tasks', // TODO: localize
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<WorkqueueTask>>(
                future: _tasksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No assigned tasks'); // TODO: localize
                  }
                  final tasks = snapshot.data!.take(5).toList();
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      Color chipColor;
                      switch (task.status) {
                        case 'Completed':
                          chipColor = Colors.green;
                          break;
                        case 'InProgress':
                          chipColor = Colors.orange;
                          break;
                        default:
                          chipColor = Colors.grey;
                      }
                      return ListTile(
                        title: Text(task.title),
                        trailing: Chip(
                          label: Text(
                            task.status,
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: chipColor.withValues(alpha: 0.15),
                          side: BorderSide.none,
                          labelStyle: TextStyle(color: chipColor),
                        ),
                      );
                    },
                  );
                },
              ),
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
