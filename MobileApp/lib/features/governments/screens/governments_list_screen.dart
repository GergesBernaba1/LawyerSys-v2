import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/governments_bloc.dart';
import '../bloc/governments_event.dart';
import '../bloc/governments_state.dart';
import '../models/government.dart';

class GovernmentsListScreen extends StatefulWidget {
  const GovernmentsListScreen({super.key});

  @override
  State<GovernmentsListScreen> createState() => _GovernmentsListScreenState();
}

class _GovernmentsListScreenState extends State<GovernmentsListScreen> {
  final _searchController = TextEditingController();
  List<Government> _filtered = [];

  @override
  void initState() {
    super.initState();
    context.read<GovernmentsBloc>().add(LoadGovernments());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter(List<Government> all) {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? all
          : all.where((g) => g.governorateName.toLowerCase().contains(query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Governments')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) {
                final state = context.read<GovernmentsBloc>().state;
                if (state is GovernmentsLoaded) _applyFilter(state.governments);
              },
            ),
          ),
          Expanded(
            child: BlocConsumer<GovernmentsBloc, GovernmentsState>(
              listener: (context, state) {
                if (state is GovernmentsLoaded) _applyFilter(state.governments);
              },
              builder: (context, state) {
                if (state is GovernmentsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is GovernmentsError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                if (_filtered.isEmpty && state is GovernmentsLoaded) {
                  return const Center(child: Text('No governments found'));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<GovernmentsBloc>().add(RefreshGovernments());
                  },
                  child: ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final gov = _filtered[index];
                      return ListTile(
                        leading: const Icon(Icons.location_city),
                        title: Text(gov.governorateName),
                        subtitle: Text(gov.governorateId),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
