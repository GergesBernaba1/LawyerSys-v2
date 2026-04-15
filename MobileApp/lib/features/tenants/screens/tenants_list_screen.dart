import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/tenants_repository.dart';

class TenantsListScreen extends StatefulWidget {
  const TenantsListScreen({super.key});

  @override
  State<TenantsListScreen> createState() => _TenantsListScreenState();
}

class _TenantsListScreenState extends State<TenantsListScreen> {
  bool _loading = true;
  String? _error;
  TenantSelection? _selection;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = context.read<TenantsRepository>();
      final selection = await repo.getAvailableTenants();
      if (!mounted) return;
      setState(() {
        _selection = selection;
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

  Future<void> _toggleStatus(int id, bool newValue) async {
    final repo = context.read<TenantsRepository>();
    try {
      await repo.updateTenantStatus(id, newValue);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenant status updated')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tenants')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
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

    final selection = _selection;
    if (selection == null || selection.items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(child: Text('No tenants found')),
        ],
      );
    }

    return ListView.separated(
      itemCount: selection.items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = selection.items[index];
        final id = item['id'] is int ? item['id'] as int : int.tryParse((item['id'] ?? '').toString()) ?? 0;
        final name = (item['name'] ?? '').toString();
        final country = (item['countryName'] ?? '').toString();
        final isActive = item['isActive'] == true;
        final userCount = item['userCount']?.toString() ?? '0';
        final packageName = (item['currentPackageName'] ?? '').toString();
        final current = selection.currentTenantId == id;

        return ListTile(
          leading: CircleAvatar(
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'T'),
          ),
          title: Text('$name${current ? ' (Current)' : ''}'),
          subtitle: Text([
            if (country.isNotEmpty) country,
            'Users: $userCount',
            if (packageName.isNotEmpty) 'Package: $packageName',
          ].join(' • ')),
          trailing: selection.isSuperAdmin
              ? Switch(
                  value: isActive,
                  onChanged: (v) => _toggleStatus(id, v),
                )
              : Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  color: isActive ? Colors.green : Colors.red,
                ),
        );
      },
    );
  }
}
