import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/contenders_bloc.dart';
import '../bloc/contenders_event.dart';
import '../bloc/contenders_state.dart';
import '../models/contender.dart';
import 'contender_detail_screen.dart';
import 'contender_form_screen.dart';

class ContendersListScreen extends StatefulWidget {
  const ContendersListScreen({super.key});

  @override
  State<ContendersListScreen> createState() => _ContendersListScreenState();
}

class _ContendersListScreenState extends State<ContendersListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ContendersBloc>().add(LoadContenders());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizer.contenders ?? 'Contenders')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const ContenderFormScreen()));
          context.read<ContendersBloc>().add(RefreshContenders());
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: localizer.searchContenders ?? 'Search contenders',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => context.read<ContendersBloc>().add(SearchContenders(_searchController.text)),
                ),
              ),
              onSubmitted: (value) => context.read<ContendersBloc>().add(SearchContenders(value)),
            ),
          ),
          Expanded(
            child: BlocConsumer<ContendersBloc, ContendersState>(
              listener: (context, state) {
                if (state is ContendersError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${localizer.error}: ${state.message}')));
                }
                if (state is ContenderOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                if (state is ContendersLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ContendersError) {
                  return Center(child: Text('${localizer.error}: ${state.message}'));
                }
                if (state is ContendersLoaded) {
                  final contenders = state.contenders;
                  if (contenders.isEmpty) {
                    return Center(child: Text(localizer.noData ?? 'No contenders found'));
                  }
                  return ListView.builder(
                    itemCount: contenders.length,
                    itemBuilder: (context, index) {
                      final contender = contenders[index];
                      return ListTile(
                        title: Text(contender.fullName),
                        subtitle: Text('${contender.contenderType} • ${contender.ssn}'),
                        onTap: () {
                          context.read<ContendersBloc>().add(SelectContender(contender.contenderId));
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ContenderDetailScreen(contender: contender)));
                        },
                      );
                    },
                  );
                }
                if (state is ContenderDetailLoaded) {
                  return _buildDetail(state.contender, localizer);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(ContenderModel contender, AppLocalizations localizer) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(contender.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${localizer.ssn ?? 'SSN'}: ${contender.ssn}'),
          Text('${localizer.phone ?? 'Phone'}: ${contender.phone}'),
          Text('${localizer.email ?? 'Email'}: ${contender.email}'),
          Text('${localizer.address ?? 'Address'}: ${contender.address}'),
          Text('${localizer.contenderType ?? 'Type'}: ${contender.contenderType}'),
          const SizedBox(height: 8),
          Text('${localizer.notes ?? 'Notes'}: ${contender.notes}'),
        ],
      ),
    );
  }
}
