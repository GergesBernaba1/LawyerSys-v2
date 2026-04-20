import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../bloc/case_relations_bloc.dart';
import '../bloc/case_relations_event.dart';
import '../bloc/case_relations_state.dart';
import '../repositories/case_relations_repository.dart';

class CaseRelationsSection extends StatelessWidget {
  final int caseId;

  const CaseRelationsSection({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => CaseRelationsBloc(
        repository: CaseRelationsRepository(ApiClient()),
      )..add(LoadCaseRelations(caseId)),
      child: _CaseRelationsSectionBody(caseId: caseId),
    );
  }
}

class _CaseRelationsSectionBody extends StatelessWidget {
  final int caseId;

  const _CaseRelationsSectionBody({required this.caseId});

  Future<void> _showAddDialog(BuildContext context) async {
    final relatedCaseIdCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedType = 'Related';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Add Case Relation'), // TODO: localize
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: relatedCaseIdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Related Case ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Relation Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Related', child: Text('Related')),
                        DropdownMenuItem(value: 'Appeal', child: Text('Appeal')),
                        DropdownMenuItem(
                            value: 'Consolidated', child: Text('Consolidated')),
                        DropdownMenuItem(
                            value: 'Companion', child: Text('Companion')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedType = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final relatedId =
                        int.tryParse(relatedCaseIdCtrl.text.trim());
                    if (relatedId == null || relatedId <= 0) return;
                    context.read<CaseRelationsBloc>().add(
                          CreateCaseRelation(
                            caseId: caseId,
                            relatedCaseId: relatedId,
                            relationType: selectedType,
                            notes: notesCtrl.text.trim().isEmpty
                                ? null
                                : notesCtrl.text.trim(),
                          ),
                        );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    relatedCaseIdCtrl.dispose();
    notesCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CaseRelationsBloc, CaseRelationsState>(
      listener: (context, state) {
        if (state is CaseRelationSuccess) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is CaseRelationsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
              child: Text(
                'Related Cases', // TODO: localize
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (state is CaseRelationsLoading)
              const Center(child: CircularProgressIndicator())
            else if (state is CaseRelationsLoaded && state.relations.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No related cases',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else if (state is CaseRelationsLoaded)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.relations.length,
                itemBuilder: (context, index) {
                  final relation = state.relations[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        relation.relatedCaseNumber ??
                            'Case #${relation.relatedCaseId}',
                        style:
                            const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: relation.notes != null &&
                              relation.notes!.isNotEmpty
                          ? Text(relation.notes!)
                          : null,
                      leading: Chip(
                        label: Text(
                          relation.relationType,
                          style: const TextStyle(fontSize: 11),
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          context.read<CaseRelationsBloc>().add(
                                DeleteCaseRelation(relation.id, caseId),
                              );
                        },
                      ),
                    ),
                  );
                },
              )
            else if (state is CaseRelationsError)
              Text(
                'Failed to load relations',
                style: TextStyle(color: Colors.red.shade700),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Relation'), // TODO: localize
            ),
          ],
        );
      },
    );
  }
}
