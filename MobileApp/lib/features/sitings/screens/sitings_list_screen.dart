import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/sitings/bloc/sitings_bloc.dart';
import 'package:qadaya_lawyersys/features/sitings/bloc/sitings_event.dart';
import 'package:qadaya_lawyersys/features/sitings/bloc/sitings_state.dart';
import 'package:qadaya_lawyersys/features/sitings/models/siting_model.dart';

const _kPrimary = Color(0xFF14345A);
const _kPrimaryLight = Color(0xFF2D6A87);
const _kText = Color(0xFF0F172A);
const _kTextSecondary = Color(0xFF5F7085);

class SitingsListScreen extends StatefulWidget {
  const SitingsListScreen({super.key});

  @override
  State<SitingsListScreen> createState() => _SitingsListScreenState();
}

class _SitingsListScreenState extends State<SitingsListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SitingsBloc>().add(LoadSitings());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showSitingDialog(SitingModel? siting) async {
    final caseCodeCtrl = TextEditingController(text: siting?.caseCode ?? '');
    final courtIdCtrl = TextEditingController(
        text: siting?.courtId != null ? siting!.courtId.toString() : '',);
    final notesCtrl = TextEditingController(text: siting?.notes ?? '');
    DateTime selectedDate = siting?.sitingDate ?? DateTime.now();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                siting == null
                    ? AppLocalizations.of(context)!.courtSittings
                    : AppLocalizations.of(context)!.courtSittings,
                style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: caseCodeCtrl,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.caseCode,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.allFieldsAreRequired : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: courtIdCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.courtId,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(_formatDateTime(selectedDate)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: const BorderSide(color: _kPrimary),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate == null) return;
                          if (!ctx.mounted) return;
                          final pickedTime = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                          );
                          if (pickedTime == null) return;
                          setDialogState(() {
                            selectedDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.notes,
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final data = <String, dynamic>{
                      'caseCode': caseCodeCtrl.text.trim(),
                      if (courtIdCtrl.text.trim().isNotEmpty)
                        'courtId': int.tryParse(courtIdCtrl.text.trim()),
                      'sitingDate': selectedDate.toIso8601String(),
                      'notes': notesCtrl.text.trim(),
                    };
                    if (siting == null) {
                      context.read<SitingsBloc>().add(CreateSiting(data));
                    } else {
                      context.read<SitingsBloc>().add(UpdateSiting(siting.id, data));
                    }
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    siting == null ? AppLocalizations.of(context)!.add : AppLocalizations.of(context)!.save,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(SitingModel siting) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCourtSitting),
        content: Text(l10n.deleteCourtSittingConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && mounted) {
      context.read<SitingsBloc>().add(DeleteSiting(siting.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.courtSittings),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        onPressed: () => _showSitingDialog(null),
        tooltip: AppLocalizations.of(context)!.addCourtSitting,
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<SitingsBloc, SitingsState>(
        listener: (context, state) {
          if (state is SitingOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<SitingsBloc>().add(LoadSitings(search: _searchController.text.isEmpty ? null : _searchController.text));
          }
          if (state is SitingsError) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchSittings,
                    prefixIcon: const Icon(Icons.search, color: _kPrimaryLight),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<SitingsBloc>().add(LoadSitings());
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: _kPrimary.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (value) {
                    context.read<SitingsBloc>().add(
                      LoadSitings(search: value.isEmpty ? null : value),
                    );
                  },
                  onChanged: (value) {
                    setState(() {}); // rebuild to show/hide clear button
                  },
                ),
              ),
              Expanded(
                child: _buildBody(state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(SitingsState state) {
    if (state is SitingsLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }

    if (state is SitingsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: _kTextSecondary),
            const SizedBox(height: 16),
            Text(
              '${AppLocalizations.of(context)!.error}: ${state.message}',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    if (state is SitingsLoaded) {
      if (state.sitings.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gavel, size: 64, color: _kTextSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.noCourtSittingsFound,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kTextSecondary,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: _kPrimary,
        onRefresh: () async {
          context.read<SitingsBloc>().add(RefreshSitings());
        },
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: state.sitings.length,
          separatorBuilder: (_, __) =>
              Divider(color: _kPrimary.withValues(alpha: 0.08), height: 1),
          itemBuilder: (context, index) {
            final siting = state.sitings[index];
            return _SitingTile(
              siting: siting,
              formatDateTime: _formatDateTime,
              onEdit: () => _showSitingDialog(siting),
              onDelete: () => _confirmDelete(siting),
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _SitingTile extends StatelessWidget {

  const _SitingTile({
    required this.siting,
    required this.formatDateTime,
    required this.onEdit,
    required this.onDelete,
  });
  final SitingModel siting;
  final String Function(DateTime) formatDateTime;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = siting.caseTitle?.isNotEmpty ?? false
        ? siting.caseTitle!
        : (siting.caseCode ?? 'N/A');
    final subtitle = [
      if (siting.courtName?.isNotEmpty ?? false) siting.courtName!,
      formatDateTime(siting.sitingDate),
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _kText.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.gavel, color: _kPrimary, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: _kTextSecondary),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (ctx) {
            final l10n = AppLocalizations.of(ctx)!;
            return [
              PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
              PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
            ];
          },
        ),
      ),
    );
  }
}
