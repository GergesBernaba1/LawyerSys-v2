import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/auth/permissions.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_bloc.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_state.dart';
import 'package:qadaya_lawyersys/features/authentication/models/user_session.dart';
import 'package:qadaya_lawyersys/features/employees/bloc/employees_bloc.dart';
import 'package:qadaya_lawyersys/features/employees/bloc/employees_event.dart';
import 'package:qadaya_lawyersys/features/employees/bloc/employees_state.dart';
import 'package:qadaya_lawyersys/features/employees/models/employee.dart';
import 'package:qadaya_lawyersys/features/employees/repositories/employees_repository.dart';
import 'package:qadaya_lawyersys/features/workqueue/models/workqueue_task.dart';
import 'package:qadaya_lawyersys/features/workqueue/repositories/workqueue_repository.dart';

const _kPrimary = Color(0xFF14345A);
const _kPrimaryLight = Color(0xFF2D6A87);
const _kText = Color(0xFF0F172A);
const _kTextSecondary = Color(0xFF5F7085);
const _kBg = Color(0xFFF3F6FA);

class EmployeeDetailScreen extends StatefulWidget {
  const EmployeeDetailScreen({super.key, required this.employeeModel});

  final EmployeeModel employeeModel;

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  final _salaryController = TextEditingController();
  bool _isEditingSalary = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  late final Future<List<WorkqueueTask>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _salaryController.text = widget.employeeModel.salary.toString();
    _tasksFuture = WorkqueueRepository(ApiClient())
        .getTasksByEmployee(widget.employeeModel.usersId);
  }

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  String get _displayName {
    final user = widget.employeeModel.user;
    final identity = widget.employeeModel.identity;
    if (user?.fullName.isNotEmpty ?? false) return user!.fullName;
    if (identity?.fullName.isNotEmpty ?? false) return identity!.fullName;
    return identity?.email ?? '?';
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;

    setState(() => _isUploadingImage = true);
    try {
      final repo = RepositoryProvider.of<EmployeesRepository>(context);
      await repo.uploadProfileImage(widget.employeeModel.id, picked.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profilePhotoUpdated),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.uploadFailed}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _saveSalary() {
    final l = AppLocalizations.of(context)!;
    final parsed = int.tryParse(_salaryController.text.trim());
    if (parsed == null || parsed < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.allFieldsAreRequired)),
      );
      return;
    }
    setState(() => _isSaving = true);
    context.read<EmployeesBloc>().add(
          UpdateEmployee(
            EmployeeModel(
              id: widget.employeeModel.id,
              salary: parsed,
              usersId: widget.employeeModel.usersId,
              user: widget.employeeModel.user,
              identity: widget.employeeModel.identity,
              profileImagePath: widget.employeeModel.profileImagePath,
              lastSyncedAt: DateTime.now(),
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final UserSession? session =
        authState is AuthAuthenticated ? authState.session : null;
    final canEditSalary =
        (session?.hasPermission(Permissions.editEmployees) ?? false) &&
            (session?.isAdmin() ?? false);
    final name = _displayName;

    return BlocListener<EmployeesBloc, EmployeesState>(
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l.error}: ${state.message}')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          title: Text(l.employeeDetails),
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (_isUploadingImage)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.add_a_photo_outlined),
                tooltip: l.uploadProfilePhoto,
                onPressed: _pickAndUploadImage,
              ),
            if (canEditSalary)
              IconButton(
                icon: Icon(_isEditingSalary ? Icons.save_outlined : Icons.edit_outlined),
                tooltip: _isEditingSalary ? l.save : l.edit,
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
        body: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _buildHeader(name),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(l, canEditSalary),
                  const SizedBox(height: 16),
                  _buildTasksSection(l),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kPrimaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'E',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if ((widget.employeeModel.user?.job ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.employeeModel.user!.job,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(AppLocalizations l, bool canEditSalary) {
    final email = widget.employeeModel.identity?.email ?? '';
    final phone = widget.employeeModel.user?.phoneNumber ?? '';
    final job = widget.employeeModel.user?.job ?? '';
    final salaryFmt =
        NumberFormat('#,##0').format(widget.employeeModel.salary);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(l.employeeInformation),
          const SizedBox(height: 12),
          if (email.isNotEmpty) _InfoRow(Icons.email_outlined, l.email, email),
          if (phone.isNotEmpty)
            _InfoRow(Icons.phone_outlined, l.phoneNumber, phone),
          if (job.isNotEmpty) _InfoRow(Icons.work_outline, l.job, job),
          const Divider(height: 24),
          _InfoRow(
            Icons.attach_money_outlined,
            l.salary,
            _isEditingSalary ? null : '$salaryFmt ${l.egp}',
            trailing: _isEditingSalary
                ? _SalaryField(controller: _salaryController, isSaving: _isSaving)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection(AppLocalizations l) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(l.myTasks),
          const SizedBox(height: 12),
          FutureBuilder<List<WorkqueueTask>>(
            future: _tasksFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: _kPrimary),
                  ),
                );
              }
              final tasks = snap.data ?? [];
              if (tasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l.noAssignedTasks,
                    style: const TextStyle(color: _kTextSecondary),
                  ),
                );
              }
              return Column(
                children: tasks.take(5).map(_TaskTile.new).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kText.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _kPrimary,
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value, {this.trailing});
  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _kPrimaryLight),
            const SizedBox(width: 10),
            SizedBox(
              width: 90,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: _kTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: trailing ??
                  Text(
                    value ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kText,
                    ),
                  ),
            ),
          ],
        ),
      );
}

class _SalaryField extends StatelessWidget {
  const _SalaryField({required this.controller, required this.isSaving});
  final TextEditingController controller;
  final bool isSaving;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 36,
        child: TextField(
          controller: controller,
          enabled: !isSaving,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 14, color: _kText),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kPrimary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
          ),
        ),
      );
}

class _TaskTile extends StatelessWidget {
  const _TaskTile(this.task);
  final WorkqueueTask task;

  @override
  Widget build(BuildContext context) {
    final Color chipColor = switch (task.status) {
      'Completed' => Colors.green,
      'InProgress' => Colors.orange,
      _ => Colors.grey,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              task.title,
              style: const TextStyle(fontSize: 14, color: _kText),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              task.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: chipColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
