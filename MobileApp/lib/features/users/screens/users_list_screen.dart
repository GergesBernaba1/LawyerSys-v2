import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../../authentication/bloc/auth_bloc.dart';
import '../../authentication/bloc/auth_state.dart';
import '../../authentication/models/user_session.dart';
import '../bloc/users_bloc.dart';
import '../bloc/users_event.dart';
import '../bloc/users_state.dart';
import '../models/user_model.dart';

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
    final isEdit = user != null;

    final firstNameController = TextEditingController(
        text: isEdit ? (user.fullName.split(' ').firstOrNull ?? '') : '');
    final lastNameController = TextEditingController(
        text: isEdit
            ? (user.fullName.split(' ').skip(1).join(' '))
            : '');
    final emailController = TextEditingController(text: isEdit ? (user.email ?? '') : '');
    final passwordController = TextEditingController();
    final phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    final jobController = TextEditingController(text: user?.job ?? '');
    String selectedRole = 'Employee';
    bool isActive = isEdit ? user.isActive : true;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(isEdit
                  ? 'Edit User' // TODO: localize
                  : 'Create User'), // TODO: localize
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name', // TODO: localize
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null, // TODO: localize
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name', // TODO: localize
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null, // TODO: localize
                      ),
                      if (!isEdit) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email', // TODO: localize
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null, // TODO: localize
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password', // TODO: localize
                          ),
                          obscureText: true,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null, // TODO: localize
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number', // TODO: localize
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: jobController,
                        decoration: const InputDecoration(
                          labelText: 'Job', // TODO: localize
                        ),
                      ),
                      if (!isEdit) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Role', // TODO: localize
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Employee', child: Text('Employee')), // TODO: localize
                            DropdownMenuItem(
                                value: 'Admin', child: Text('Admin')), // TODO: localize
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
                            const Text('Active'), // TODO: localize
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
                  child: const Text('Cancel'), // TODO: localize
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
                          ));
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
                          ));
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(isEdit ? 'Update' : 'Create'), // TODO: localize
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
    String selectedRole = 'Employee';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Change Role'), // TODO: localize
            content: DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role', // TODO: localize
              ),
              items: const [
                DropdownMenuItem(value: 'Employee', child: Text('Employee')), // TODO: localize
                DropdownMenuItem(value: 'Admin', child: Text('Admin')), // TODO: localize
                DropdownMenuItem(value: 'SuperAdmin', child: Text('SuperAdmin')), // TODO: localize
              ],
              onChanged: (v) {
                if (v != null) setDialogState(() => selectedRole = v);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'), // TODO: localize
              ),
              ElevatedButton(
                onPressed: () {
                  context
                      .read<UsersBloc>()
                      .add(ChangeUserRole(id: user.id, role: selectedRole));
                  Navigator.pop(ctx);
                },
                child: const Text('Confirm'), // TODO: localize
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'), // TODO: localize
        content: Text(
            'Are you sure you want to delete "${user.fullName.isNotEmpty ? user.fullName : user.userName}"?'), // TODO: localize
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')), // TODO: localize
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', // TODO: localize
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
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
              SnackBar(content: Text('${l.error}: ${state.message}')));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l.users)),
        floatingActionButton: isAdmin
            ? FloatingActionButton(
                tooltip: 'Create User', // TODO: localize
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
                    ]);
                  }
                  if (state is UsersLoaded) {
                    if (state.users.isEmpty) {
                      return ListView(children: [
                        const SizedBox(height: 80),
                        Center(child: Text(l.noUsersFound)),
                      ]);
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
                              if (!user.isActive) 'Inactive', // TODO: localize
                            ].join(' • ')),
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
                                          const Text('Edit'), // TODO: localize
                                        ]),
                                      ),
                                      PopupMenuItem(
                                        value: 'change_role',
                                        child: Row(children: [
                                          const Icon(Icons.manage_accounts, size: 18),
                                          const SizedBox(width: 8),
                                          const Text('Change Role'), // TODO: localize
                                        ]),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(children: [
                                          const Icon(Icons.delete,
                                              size: 18, color: Colors.red),
                                          const SizedBox(width: 8),
                                          const Text('Delete', // TODO: localize
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ]),
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
