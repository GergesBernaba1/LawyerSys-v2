import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/consultations_bloc.dart';
import '../bloc/consultations_event.dart';
import '../bloc/consultations_state.dart';
import '../models/consultation.dart';
import 'consultation_detail_screen.dart';

class ConsultationsListScreen extends StatefulWidget {
  const ConsultationsListScreen({super.key});

  @override
  State<ConsultationsListScreen> createState() => _ConsultationsListScreenState();
}

class _ConsultationsListScreenState extends State<ConsultationsListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ConsultationsBloc>().add(LoadConsultations());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.translate('consultations'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.search,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => context.read<ConsultationsBloc>().add(SearchConsultations(_searchController.text)),
                ),
              ),
              onSubmitted: (v) => context.read<ConsultationsBloc>().add(SearchConsultations(v)),
            ),
          ),
          Expanded(
            child: BlocConsumer<ConsultationsBloc, ConsultationsState>(
              listener: (context, state) {
                if (state is ConsultationsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l.error}: ${state.message}')),
                  );
                }
                if (state is ConsultationOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                if (state is ConsultationsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ConsultationsError) {
                  return Center(child: Text('${l.error}: ${state.message}'));
                }
                if (state is ConsultationsLoaded) {
                  final items = state.consultations;
                  if (items.isEmpty) {
                    return Center(child: Text(l.noData));
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        context.read<ConsultationsBloc>().add(RefreshConsultations()),
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) => _ConsultationTile(
                        consultation: items[index],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<ConsultationsBloc>(),
                              child: ConsultationDetailScreen(consultation: items[index]),
                            ),
                          ),
                        ),
                      ),
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

class _ConsultationTile extends StatelessWidget {
  final ConsultationModel consultation;
  final VoidCallback onTap;

  const _ConsultationTile({required this.consultation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(consultation.subject),
      subtitle: Text(
        '${consultation.customerFullName ?? ''} • ${consultation.status}',
      ),
      trailing: Text(
        '${consultation.consultationDate.day}/${consultation.consultationDate.month}/${consultation.consultationDate.year}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: onTap,
    );
  }
}
