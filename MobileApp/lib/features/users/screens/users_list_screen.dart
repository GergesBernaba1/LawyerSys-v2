import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../repositories/users_repository.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _users = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = context.read<UsersRepository>();
      final users = await repo.getUsers(search: search);
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
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
                  onPressed: () => _load(search: _searchController.text),
                ),
              ),
              onSubmitted: (value) => _load(search: value),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(search: _searchController.text),
              child: _buildBody(l),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(child: Text('Error: $_error')),
        ],
      );
    }

    if (_users.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(child: Text(l.noDataAvailable)),
        ],
      );
    }

    return ListView.separated(
      itemCount: _users.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = _users[index];
        final fullName = (user['fullName'] ?? user['FullName'] ?? '').toString();
        final userName = (user['userName'] ?? user['UserName'] ?? '').toString();
        final phone = (user['phoneNumber'] ?? user['PhoneNumber'] ?? '').toString();
        final job = (user['job'] ?? user['Job'] ?? '').toString();

        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(fullName.isNotEmpty ? fullName : userName),
          subtitle: Text([
            if (userName.isNotEmpty) '@$userName',
            if (job.isNotEmpty) job,
            if (phone.isNotEmpty) phone,
          ].join(' • ')),
        );
      },
    );
  }
}
