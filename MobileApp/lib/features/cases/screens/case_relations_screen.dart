import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../core/localization/app_localizations.dart';
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
              title: Text(AppLocalizations.of(context)!.addCaseRelation),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: relatedCaseIdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.relatedCaseId,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownMenu<String>(
                      initialSelection: selectedType,
                      label: Text(AppLocalizations.of(context)!.relationType),
                      expandedInsets: EdgeInsets.zero,
                      onSelected: (v) {
                        if (v != null) setDialogState(() => selectedType = v);
                      },
                      dropdownMenuEntries: [
                        DropdownMenuEntry(value: 'Related', label: AppLocalizations.of(context)!.relationTypeRelated),
                        DropdownMenuEntry(value: 'Appeal', label: AppLocalizations.of(context)!.relationTypeAppeal),
                        DropdownMenuEntry(value: 'Consolidated', label: AppLocalizations.of(context)!.relationTypeConsolidated),
                        DropdownMenuEntry(value: 'Companion', label: AppLocalizations.of(context)!.relationTypeCompanion),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.notesOptional,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context)!.cancel),
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
                  child: Text(AppLocalizations.of(context)!.add),
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
              content: Text('${AppLocalizations.of(context)!.error}: ${state.message}'),
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
                AppLocalizations.of(context)!.caseRelations,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (state is CaseRelationsLoading)
              const Center(child: CircularProgressIndicator())
            else if (state is CaseRelationsLoaded && state.relations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  AppLocalizations.of(context)!.noRelationsFound,
                  style: const TextStyle(color: Colors.grey),
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
                AppLocalizations.of(context)!.failedToLoadRelations,
                style: TextStyle(color: Colors.red.shade700),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.addRelation),
            ),
          ],
        );
      },
    );
  }
}
