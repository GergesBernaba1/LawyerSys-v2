import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/users_bloc.dart';
import '../bloc/users_event.dart';
import '../bloc/users_state.dart';

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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.users)),
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
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(displayName),
                          subtitle: Text([
                            if (user.userName.isNotEmpty) '@${user.userName}',
                            if (user.job != null && user.job!.isNotEmpty)
                              user.job!,
                            if (user.phoneNumber != null &&
                                user.phoneNumber!.isNotEmpty)
                              user.phoneNumber!,
                          ].join(' • ')),
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
