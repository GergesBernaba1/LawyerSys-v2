import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/localization/app_localizations.dart';
import '../../authentication/bloc/auth_bloc.dart';
import '../../authentication/bloc/auth_state.dart';
import '../bloc/cases_bloc.dart';
import '../bloc/cases_event.dart';
import '../bloc/cases_state.dart';
import '../models/case.dart';
import 'case_detail_screen.dart';
import 'case_form_screen.dart';

class CasesListScreen extends StatefulWidget {
  const CasesListScreen({super.key});

  @override
  State<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends State<CasesListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CasesBloc>().add(LoadCases());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);

    final authState = context.watch<AuthBloc>().state;
    final session = authState is AuthAuthenticated ? authState.session : null;

    return Scaffold(
      appBar: AppBar(title: Text(localizer.cases)),
      floatingActionButton: (session?.hasPermission(Permissions.createCases) ?? false)
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const CaseFormScreen()));
                context.read<CasesBloc>().add(RefreshCases());
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: BlocListener<CasesBloc, CasesState>(
        listener: (context, state) {
          if (state is CaseOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            context.read<CasesBloc>().add(RefreshCases());
          }
          if (state is CasesError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${localizer.error}: ${state.message}')));
          }
        },
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: localizer.searchCases,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => context.read<CasesBloc>().add(SearchCases(_searchController.text)),
                ),
              ),
              onSubmitted: (v) => context.read<CasesBloc>().add(SearchCases(v)),
            ),
          ),
          Expanded(
            child: BlocBuilder<CasesBloc, CasesState>(
              builder: (context, state) {
                if (state is CasesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CasesError) {
                  return Center(child: Text('${localizer.error}: ${state.message}'));
                }
                if (state is CasesLoaded) {
                  final cases = state.cases;
                  if (cases.isEmpty) {
                    return Center(child: Text(localizer.noCasesFound));
                  }
                  return ListView.builder(
                    itemCount: cases.length,
                    itemBuilder: (context, index) {
                      final caseItem = cases[index];
                      return ListTile(
                        title: Text(caseItem.caseNumber),
                        subtitle: Text('${caseItem.customerFullName} • ${caseItem.caseStatus}'),
                        onTap: () {
                          context.read<CasesBloc>().add(SelectCase(caseItem.caseId));
                          Navigator.push(context, MaterialPageRoute(builder: (context) => CaseDetailScreen(caseModel: caseItem)));
                        },
                      );
                    },
                  );
                }
                if (state is CaseDetailLoaded) {
                  return _buildDetail(state.detail);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(CaseModel caseModel) {
    final localizer = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${localizer.caseNumber} #${caseModel.caseNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('${localizer.customer}: ${caseModel.customerFullName}'),
          Text('${localizer.status}: ${caseModel.caseStatus}'),
        ],
      ),
    );
  }
}

