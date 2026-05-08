import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:qadaya_lawyersys/core/auth/permissions.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_bloc.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_state.dart';
import 'package:qadaya_lawyersys/features/authentication/models/user_session.dart';
import 'package:qadaya_lawyersys/features/employees/bloc/employees_bloc.dart';
import 'package:qadaya_lawyersys/features/employees/bloc/employees_event.dart';
import 'package:qadaya_lawyersys/features/employees/bloc/employees_state.dart';
import 'package:qadaya_lawyersys/features/employees/models/employee.dart';
import 'package:qadaya_lawyersys/features/employees/screens/employee_detail_screen.dart';
import 'package:qadaya_lawyersys/features/users/repositories/users_repository.dart';

const _kPrimary = Color(0xFF14345A);
const _kPrimaryLight = Color(0xFF2D6A87);
const _kText = Color(0xFF0F172A);
const _kTextSecondary = Color(0xFF5F7085);

class EmployeesListScreen extends StatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  State<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<EmployeesBloc>().add(LoadEmployees());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<EmployeesBloc>().add(SearchEmployees(value.trim()));
      }
    });
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<EmployeesBloc>()..add(RefreshEmployees());
    await bloc.stream.firstWhere(
      (s) => s is EmployeesLoaded || s is EmployeesError,
      orElse: () => bloc.state,
    );
  }

  Future<void> _confirmDelete(int employeeId) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteEmployee),
        content: Text(l.deleteEmployeeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete,
                style: const TextStyle(color: Colors.red),),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && mounted) {
      context.read<EmployeesBloc>().add(DeleteEmployee(employeeId));
    }
  }

  // ── Create by linking an existing user ──────────────────────────────────────
  Future<void> _showLinkUserDialog() async {
    final l = AppLocalizations.of(context)!;
    final usersRepo = RepositoryProvider.of<UsersRepository>(context);

    List<Map<String, dynamic>> users = [];
    int? selectedUserId;
    final salaryCtrl = TextEditingController();
    bool loadingUsers = true;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          if (loadingUsers) {
            usersRepo.getUsers().then((list) {
              setDialogState(() {
                users = list;
                loadingUsers = false;
              });
            }).catchError((_) {
              setDialogState(() => loadingUsers = false);
            });
          }

          return AlertDialog(
            title: Text(l.linkExistingUser),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loadingUsers)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(),
                    )
                  else
                    DropdownButtonFormField<int>(
                      initialValue: selectedUserId,
                      decoration: InputDecoration(labelText: l.employee),
                      items: users
                          .map((u) => DropdownMenuItem<int>(
                                value: int.tryParse('${u['id']}'),
                                child: Text(
                                  '${u['fullName'] ?? u['email'] ?? u['userName'] ?? 'User'}',
                                ),
                              ),)
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedUserId = v),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: salaryCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l.salary),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(l.cancel),
              ),
              TextButton(
                onPressed: selectedUserId == null
                    ? null
                    : () {
                        final salary =
                            int.tryParse(salaryCtrl.text.trim()) ?? 0;
                        Navigator.pop(dialogCtx);
                        context.read<EmployeesBloc>().add(
                              CreateEmployee(EmployeeModel(
                                id: 0,
                                salary: salary,
                                usersId: selectedUserId!,
                              ),),
                            );
                      },
                child: Text(l.create),
              ),
            ],
          );
        },
      ),
    );
    salaryCtrl.dispose();
  }

  // ── Create a brand-new user + employee in one step ───────────────────────────
  Future<void> _showCreateWithUserDialog() async {
    final l = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();

    final fullNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final jobCtrl = TextEditingController();
    final ssnCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    DateTime? dob;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(l.createWithNewUser),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogField(fullNameCtrl, l.fullName, required: true),
                    _dialogField(emailCtrl, l.email,
                        keyboard: TextInputType.emailAddress,),
                    _dialogField(usernameCtrl, l.username),
                    _dialogField(passwordCtrl, l.password,
                        required: true, obscure: true,),
                    _dialogField(phoneCtrl, l.phoneNumber,
                        keyboard: TextInputType.phone,),
                    _dialogField(jobCtrl, l.job, required: true),
                    _dialogField(ssnCtrl, l.ssn, required: true),
                    _dialogField(addressCtrl, l.address),
                    _dialogField(salaryCtrl, l.salary,
                        keyboard: TextInputType.number,),
                    const SizedBox(height: 8),
                    // Date of birth picker
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogCtx,
                          initialDate: DateTime(1990),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          builder: (c, child) => Theme(
                            data: Theme.of(c).copyWith(
                              colorScheme:
                                  const ColorScheme.light(primary: _kPrimary),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() => dob = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l.dateOfBirth,
                          border: const OutlineInputBorder(),
                        ),
                        child: Text(
                          dob != null
                              ? DateFormat('yyyy-MM-dd').format(dob!)
                              : l.dateOfBirth,
                          style: TextStyle(
                            color: dob != null ? _kText : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final salary = int.tryParse(salaryCtrl.text.trim()) ?? 0;
                Navigator.pop(dialogCtx);
                // Send CreateEmployeeWithUser via bloc event using raw data
                // The bloc passes this to POST /api/employees/withuser
                context.read<EmployeesBloc>().add(
                      CreateEmployee(EmployeeModel(
                        id: 0,
                        salary: salary,
                        usersId: 0,
                        user: UserModel(
                          id: 0,
                          fullName: fullNameCtrl.text.trim(),
                          address: addressCtrl.text.trim(),
                          job: jobCtrl.text.trim(),
                          phoneNumber: phoneCtrl.text.trim(),
                          ssn: ssnCtrl.text.trim(),
                          userName: usernameCtrl.text.trim().isNotEmpty
                              ? usernameCtrl.text.trim()
                              : emailCtrl.text.trim(),
                          dateOfBirth: dob != null
                              ? DateOnly(
                                  year: dob!.year,
                                  month: dob!.month,
                                  day: dob!.day,
                                )
                              : null,
                        ),
                        identity: emailCtrl.text.trim().isNotEmpty
                            ? IdentityUserInfoModel(
                                id: '',
                                userName: usernameCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                fullName: fullNameCtrl.text.trim(),
                                emailConfirmed: false,
                                requiresPasswordReset: false,
                              )
                            : null,
                      ),),
                    );
              },
              child: Text(l.create),
            ),
          ],
        ),
      ),
    );

    for (final c in [
      fullNameCtrl, emailCtrl, usernameCtrl, passwordCtrl,
      phoneCtrl, jobCtrl, ssnCtrl, addressCtrl, salaryCtrl,
    ]) {
      c.dispose();
    }
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty)
                  ? AppLocalizations.of(context)!.allFieldsAreRequired
                  : null
              : null,
        ),
      );

  void _showCreateMenu(UserSession? session) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_add_outlined, color: _kPrimary),
              title: Text(l.createWithNewUser),
              onTap: () {
                Navigator.pop(context);
                _showCreateWithUserDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_outlined, color: _kPrimaryLight),
              title: Text(l.linkExistingUser),
              onTap: () {
                Navigator.pop(context);
                _showLinkUserDialog();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final session = authState is AuthAuthenticated ? authState.session : null;
    final canManage = (session?.hasPermission(Permissions.createEmployees) ?? false) &&
        (session?.isAdmin() ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.employees),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              backgroundColor: _kPrimary,
              onPressed: () => _showCreateMenu(session),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.searchEmployees,
                prefixIcon: const Icon(Icons.search, color: _kPrimaryLight),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: _kTextSecondary),
                        onPressed: () {
                          _searchController.clear();
                          context.read<EmployeesBloc>().add(LoadEmployees());
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: _kPrimary.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (v) {
                setState(() {});
                _onSearchChanged(v);
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocConsumer<EmployeesBloc, EmployeesState>(
              listener: (context, state) {
                if (state is EmployeeOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                  context.read<EmployeesBloc>().add(RefreshEmployees());
                }
                if (state is EmployeesError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${l.error}: ${state.message}'),),
                  );
                }
              },
              builder: (context, state) {
                if (state is EmployeesLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: _kPrimary),
                  );
                }

                if (state is EmployeesError) {
                  return RefreshIndicator(
                    color: _kPrimary,
                    onRefresh: _onRefresh,
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 48, color: _kTextSecondary,),
                                const SizedBox(height: 16),
                                Text(
                                  '${l.error}: ${state.message}',
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is EmployeesLoaded) {
                  final employees = state.employees;

                  if (employees.isEmpty) {
                    return RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: _onRefresh,
                      child: ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 64,
                                      color:
                                          _kTextSecondary.withValues(alpha: 0.5),),
                                  const SizedBox(height: 16),
                                  Text(l.noEmployeesFound,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _kTextSecondary,
                                      ),),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: _kPrimary,
                    onRefresh: _onRefresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4,),
                      itemCount: employees.length,
                      separatorBuilder: (_, __) => Divider(
                        color: _kPrimary.withValues(alpha: 0.08),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final emp = employees[index];
                        return _EmployeeTile(
                          employee: emp,
                          canManage: canManage,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  EmployeeDetailScreen(employeeModel: emp),
                            ),
                          ),
                          onDelete: () => _confirmDelete(emp.id),
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
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({
    required this.employee,
    required this.canManage,
    required this.onTap,
    required this.onDelete,
  });

  final EmployeeModel employee;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final fullName = (employee.user?.fullName.isNotEmpty ?? false)
        ? employee.user!.fullName
        : ((employee.identity?.fullName.isNotEmpty ?? false)
            ? employee.identity!.fullName
            : (employee.identity?.email ?? '?'));
    final job = employee.user?.job ?? '';
    final email = employee.identity?.email ?? '';
    final salary = NumberFormat('#,##0').format(employee.salary);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _kText.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: _kPrimary.withValues(alpha: 0.12),
          child: Text(
            fullName.isNotEmpty ? fullName[0].toUpperCase() : 'E',
            style: const TextStyle(
              color: _kPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          fullName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (job.isNotEmpty)
              Text(
                '${l.job}: $job',
                style: const TextStyle(fontSize: 12, color: _kTextSecondary),
              ),
            if (email.isNotEmpty)
              Text(
                email,
                style: const TextStyle(fontSize: 11, color: _kTextSecondary),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  salary,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _kPrimary,
                  ),
                ),
                Text(
                  l.egp,
                  style: const TextStyle(fontSize: 10, color: _kTextSecondary),
                ),
              ],
            ),
            if (canManage) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l.delete,
                        style: const TextStyle(color: Colors.red),),
                  ),
                ],
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
