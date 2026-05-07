import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_bloc.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_state.dart';
import 'package:qadaya_lawyersys/features/authentication/models/user_session.dart';
import 'package:qadaya_lawyersys/features/users/bloc/users_bloc.dart';
import 'package:qadaya_lawyersys/features/users/bloc/users_event.dart';
import 'package:qadaya_lawyersys/features/users/bloc/users_state.dart';
import 'package:qadaya_lawyersys/features/users/models/user_model.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<UsersBloc>().add(LoadUsers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isAdmin(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.session.isAdmin();
    }
    return false;
  }

  Future<void> _showUserForm(BuildContext context, UserModel? user) async {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = user != null;

    final firstNameController = TextEditingController(
        text: isEdit ? (user.fullName.split(' ').firstOrNull ?? '') : '',);
    final lastNameController = TextEditingController(
        text: isEdit
            ? (user.fullName.split(' ').skip(1).join(' '))
            : '',);
    final emailController = TextEditingController(text: isEdit ? (user.email ?? '') : '');
    final passwordController = TextEditingController();
    final phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    final jobController = TextEditingController(text: user?.job ?? '');
    String selectedRole = 'Employee';
    bool isActive = !isEdit || user.isActive;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? l10n.edit : l10n.add),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: firstNameController,
                        decoration: InputDecoration(
                          labelText: l10n.firstName,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l10n.allFieldsAreRequired : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: lastNameController,
                        decoration: InputDecoration(
                          labelText: l10n.lastName,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l10n.allFieldsAreRequired : null,
                      ),
                      if (!isEdit) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: l10n.email,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? l10n.allFieldsAreRequired : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: l10n.password,
                          ),
                          obscureText: true,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? l10n.allFieldsAreRequired : null,
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: l10n.phoneNumber,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: jobController,
                        decoration: InputDecoration(
                          labelText: l10n.job,
                        ),
                      ),
                      if (!isEdit) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedRole,
                          decoration: InputDecoration(
                            labelText: l10n.role,
                          ),
                          items: [
                            DropdownMenuItem(
                                value: 'Employee', child: Text(l10n.employee),),
                            DropdownMenuItem(
                                value: 'Admin', child: Text(l10n.admin),),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => selectedRole = v);
                            }
                          },
                        ),
                      ],
                      if (isEdit) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l10n.active),
                            Switch(
                              value: isActive,
                              onChanged: (v) => setDialogState(() => isActive = v),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    if (isEdit) {
                      context.read<UsersBloc>().add(UpdateUser(
                            id: user.id,
                            firstName: firstNameController.text.trim(),
                            lastName: lastNameController.text.trim(),
                            phoneNumber: phoneController.text.trim().isEmpty
                                ? null
                                : phoneController.text.trim(),
                            job: jobController.text.trim().isEmpty
                                ? null
                                : jobController.text.trim(),
                            isActive: isActive,
                          ),);
                    } else {
                      context.read<UsersBloc>().add(CreateUser(
                            email: emailController.text.trim(),
                            password: passwordController.text.trim(),
                            firstName: firstNameController.text.trim(),
                            lastName: lastNameController.text.trim(),
                            phoneNumber: phoneController.text.trim().isEmpty
                                ? null
                                : phoneController.text.trim(),
                            job: jobController.text.trim().isEmpty
                                ? null
                                : jobController.text.trim(),
                            role: selectedRole,
                          ),);
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(isEdit ? l10n.update : l10n.add),
                ),
              ],
            );
          },
        );
      },
    );

    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    jobController.dispose();
  }

  Future<void> _showChangeRoleDialog(BuildContext context, UserModel user) async {
    final l10n = AppLocalizations.of(context)!;
    String selectedRole = 'Employee';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(l10n.changeRole),
            content: DropdownMenu<String>(
              initialSelection: selectedRole,
              label: Text(l10n.role),
              expandedInsets: EdgeInsets.zero,
              onSelected: (v) {
                if (v != null) setDialogState(() => selectedRole = v);
              },
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 'Employee', label: l10n.employee),
                DropdownMenuEntry(value: 'Admin', label: l10n.admin),
                const DropdownMenuEntry(value: 'SuperAdmin', label: 'SuperAdmin'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  context
                      .read<UsersBloc>()
                      .add(ChangeUserRole(id: user.id, role: selectedRole));
                  Navigator.pop(ctx);
                },
                child: Text(l10n.confirm),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, UserModel user) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteUser),
        content: Text(
            '${l10n.delete} "${user.fullName.isNotEmpty ? user.fullName : user.userName}"?',),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.delete,
                  style: const TextStyle(color: Colors.red),),),
        ],
      ),
    );
    if ((confirmed ?? false) && context.mounted) {
      context.read<UsersBloc>().add(DeleteUser(user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isAdmin = _isAdmin(context);

    return BlocListener<UsersBloc, UsersState>(
      listener: (context, state) {
        if (state is UserOperationSuccess) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is UsersError) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l.error}: ${state.message}')),);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l.users)),
        floatingActionButton: isAdmin
            ? FloatingActionButton(
                tooltip: l.add,
                onPressed: () => _showUserForm(context, null),
                child: const Icon(Icons.add),
              )
            : null,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l.search,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => context
                        .read<UsersBloc>()
                        .add(SearchUsers(_searchController.text)),
                  ),
                ),
                onSubmitted: (value) =>
                    context.read<UsersBloc>().add(SearchUsers(value)),
              ),
            ),
            Expanded(
              child: BlocBuilder<UsersBloc, UsersState>(
                builder: (context, state) {
                  if (state is UsersLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is UsersError) {
                    return ListView(children: [
                      const SizedBox(height: 80),
                      Center(child: Text('${l.error}: ${state.message}')),
                    ],);
                  }
                  if (state is UsersLoaded) {
                    if (state.users.isEmpty) {
                      return ListView(children: [
                        const SizedBox(height: 80),
                        Center(child: Text(l.noUsersFound)),
                      ],);
                    }
                    return RefreshIndicator(
                      onRefresh: () async =>
                          context.read<UsersBloc>().add(RefreshUsers()),
                      child: ListView.separated(
                        itemCount: state.users.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = state.users[index];
                          final displayName = user.fullName.isNotEmpty
                              ? user.fullName
                              : user.userName;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: user.isActive
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.15)
                                  : Colors.grey.withValues(alpha: 0.2),
                              child: Icon(
                                Icons.person,
                                color: user.isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                            ),
                            title: Text(displayName),
                            subtitle: Text([
                              if (user.userName.isNotEmpty) '@${user.userName}',
                              if (user.job != null && user.job!.isNotEmpty)
                                user.job!,
                              if (user.phoneNumber != null &&
                                  user.phoneNumber!.isNotEmpty)
                                user.phoneNumber!,
                              if (!user.isActive) l.status,
                            ].join(' • '),),
                            trailing: isAdmin
                                ? PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'edit') {
                                        _showUserForm(context, user);
                                      } else if (v == 'delete') {
                                        _confirmDelete(context, user);
                                      } else if (v == 'change_role') {
                                        _showChangeRoleDialog(context, user);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(children: [
                                          const Icon(Icons.edit, size: 18),
                                          const SizedBox(width: 8),
                                          Text(l.edit),
                                        ],),
                                      ),
                                      PopupMenuItem(
                                        value: 'change_role',
                                        child: Row(children: [
                                          const Icon(Icons.manage_accounts, size: 18),
                                          const SizedBox(width: 8),
                                          Text(l.changeRole),
                                        ],),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(children: [
                                          const Icon(Icons.delete,
                                              size: 18, color: Colors.red,),
                                          const SizedBox(width: 8),
                                          Text(l.delete,
                                              style: const TextStyle(color: Colors.red),),
                                        ],),
                                      ),
                                    ],
                                  )
                                : null,
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
