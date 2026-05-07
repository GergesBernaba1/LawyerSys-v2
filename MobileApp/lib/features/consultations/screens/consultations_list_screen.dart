import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_bloc.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_state.dart';
import 'package:qadaya_lawyersys/features/authentication/models/user_session.dart';
import 'package:qadaya_lawyersys/features/consultations/bloc/consultations_bloc.dart';
import 'package:qadaya_lawyersys/features/consultations/bloc/consultations_event.dart';
import 'package:qadaya_lawyersys/features/consultations/bloc/consultations_state.dart';
import 'package:qadaya_lawyersys/features/consultations/models/consultation.dart';
import 'package:qadaya_lawyersys/features/consultations/repositories/consultations_repository.dart';
import 'package:qadaya_lawyersys/features/consultations/screens/consultation_detail_screen.dart';

typedef RelationToggleCallback = void Function(int id, {required bool selected});

class ConsultationsListScreen extends StatefulWidget {
  const ConsultationsListScreen({super.key});

  @override
  State<ConsultationsListScreen> createState() =>
      _ConsultationsListScreenState();
}

class _ConsultationsListScreenState extends State<ConsultationsListScreen> {
  final _searchController = TextEditingController();

  final _subjectController = TextEditingController();
  final _typeController = TextEditingController();
  final _stateController = TextEditingController(text: 'Pending');
  final _descriptionController = TextEditingController();
  final _feedbackController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDateTime;
  ConsultationModel? _editing;
  bool _submitting = false;
  bool _loadingRelations = false;

  List<RelationOption> _allCustomers = const [];
  List<RelationOption> _allEmployees = const [];
  Set<int> _selectedCustomerIds = <int>{};
  Set<int> _selectedEmployeeIds = <int>{};

  @override
  void initState() {
    super.initState();
    context.read<ConsultationsBloc>().add(LoadConsultations());
    _loadReferenceOptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _subjectController.dispose();
    _typeController.dispose();
    _stateController.dispose();
    _descriptionController.dispose();
    _feedbackController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadReferenceOptions() async {
    final repo = context.read<ConsultationsRepository>();
    try {
      final customers = await repo.getCustomerOptions();
      final employees = await repo.getEmployeeOptions();
      if (!mounted) return;
      setState(() {
        _allCustomers = customers;
        _allEmployees = employees;
      });
    } catch (_) {
      // Keep list page usable even if relation lookups fail.
    }
  }

  void _resetForm() {
    _editing = null;
    _subjectController.clear();
    _typeController.clear();
    _stateController.text = 'Pending';
    _descriptionController.clear();
    _feedbackController.clear();
    _notesController.clear();
    _selectedDateTime = DateTime.now();
    _selectedCustomerIds = <int>{};
    _selectedEmployeeIds = <int>{};
  }

  Future<void> _openCreateDialog() async {
    _resetForm();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) =>
            _buildConsultationDialog(setModalState),
      ),
    );
  }

  Future<void> _openEditDialog(ConsultationModel consultation) async {
    final repo = context.read<ConsultationsRepository>();
    setState(() {
      _editing = consultation;
      _subjectController.text = consultation.subject;
      _typeController.text = consultation.type;
      _stateController.text = consultation.status;
      _descriptionController.text = consultation.details;
      _feedbackController.text = consultation.feedback ?? '';
      _notesController.text = consultation.notes ?? '';
      _selectedDateTime = consultation.consultationDate;
      _loadingRelations = true;
    });

    try {
      final customerIds =
          await repo.getConsultationCustomerIds(consultation.id);
      final employeeIds =
          await repo.getConsultationEmployeeIds(consultation.id);
      if (!mounted) return;
      setState(() {
        _selectedCustomerIds = customerIds.toSet();
        _selectedEmployeeIds = employeeIds.toSet();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedCustomerIds = <int>{};
        _selectedEmployeeIds = <int>{};
      });
    } finally {
      if (mounted) {
        setState(() => _loadingRelations = false);
      }
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) =>
            _buildConsultationDialog(setModalState),
      ),
    );
  }

  Future<void> _submitDialog(StateSetter setModalState) async {
    final localizer = AppLocalizations.of(context)!;
    final repo = context.read<ConsultationsRepository>();
    final authState = context.read<AuthBloc>().state;
    final session = authState is AuthAuthenticated ? authState.session : null;
    final isEmployeeOnly = (session?.hasRole('Employee') ?? false) &&
        session?.hasRole('Admin') != true &&
        session?.hasRole('SuperAdmin') != true;

    final subject = _subjectController.text.trim();
    final type = _typeController.text.trim();
    final state = _stateController.text.trim();
    final description = _descriptionController.text.trim();
    if (subject.isEmpty ||
        type.isEmpty ||
        state.isEmpty ||
        description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizer.allFieldsAreRequired)),
      );
      return;
    }

    setModalState(() => _submitting = true);
    try {
      final payload = ConsultationModel(
        id: _editing?.id ?? 0,
        tenantId: _editing?.tenantId ?? '',
        subject: subject,
        details: description,
        status: state,
        type: type,
        feedback: _feedbackController.text.trim().isEmpty
            ? null
            : _feedbackController.text.trim(),
        consultationDate: _selectedDateTime ?? DateTime.now(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final saved = _editing == null
          ? await repo.createConsultation(payload)
          : await repo.updateConsultation(payload);

      await repo.syncConsultationRelations(
        consultationId: saved.id,
        selectedCustomerIds: _selectedCustomerIds,
        selectedEmployeeIds: _selectedEmployeeIds,
        includeEmployees: !isEmployeeOnly,
      );

      if (!mounted) return;
      Navigator.pop(context);
      context.read<ConsultationsBloc>().add(RefreshConsultations());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editing == null
                ? localizer.consultationCreatedSuccessfully
                : localizer.consultationUpdatedSuccessfully,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizer.error}: $e')),
      );
    } finally {
      if (mounted) {
        setModalState(() => _submitting = false);
      }
    }
  }

  Future<void> _confirmDelete(ConsultationModel item) async {
    final localizer = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(localizer.delete),
            content: Text('${localizer.deleteConfirm} "${item.subject}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(localizer.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(localizer.delete),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;
    context.read<ConsultationsBloc>().add(DeleteConsultation(item.id));
  }

  Widget _buildConsultationDialog(StateSetter setModalState) {
    final localizer = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;
    final session = authState is AuthAuthenticated ? authState.session : null;
    final isEmployeeOnly = (session?.hasRole('Employee') ?? false) &&
        session?.hasRole('Admin') != true &&
        session?.hasRole('SuperAdmin') != true;

    return AlertDialog(
      title: Text(_editing == null ? localizer.create : localizer.edit),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _subjectController,
                decoration:
                    InputDecoration(labelText: localizer.consultationSubject),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _typeController,
                decoration:
                    InputDecoration(labelText: localizer.consultationType),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _stateController,
                decoration:
                    InputDecoration(labelText: localizer.consultationState),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(localizer.consultationDateTime),
                subtitle: Text(
                  _selectedDateTime == null
                      ? localizer.dateLabel
                      : '${_selectedDateTime!.year}-${_selectedDateTime!.month.toString().padLeft(2, '0')}-${_selectedDateTime!.day.toString().padLeft(2, '0')} ${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final base = _selectedDateTime ?? DateTime.now();
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: base,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate == null || !mounted) return;
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(base),
                  );
                  if (pickedTime == null || !mounted) return;
                  setModalState(() {
                    _selectedDateTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                  });
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: localizer.description),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _feedbackController,
                minLines: 2,
                maxLines: 3,
                decoration:
                    InputDecoration(labelText: localizer.consultationFeedback),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(labelText: localizer.notes),
              ),
              const SizedBox(height: 16),
              _buildRelationPicker(
                title: localizer.customers,
                options: _allCustomers,
                selectedIds: _selectedCustomerIds,
                onToggle: (id, {required selected}) {
                  setModalState(() {
                    if (selected) {
                      _selectedCustomerIds.add(id);
                    } else {
                      _selectedCustomerIds.remove(id);
                    }
                  });
                },
                localizer: localizer,
              ),
              const SizedBox(height: 12),
              if (!isEmployeeOnly)
                _buildRelationPicker(
                  title: localizer.employees,
                  options: _allEmployees,
                  selectedIds: _selectedEmployeeIds,
                  onToggle: (id, {required selected}) {
                    setModalState(() {
                      if (selected) {
                        _selectedEmployeeIds.add(id);
                      } else {
                        _selectedEmployeeIds.remove(id);
                      }
                    });
                  },
                  localizer: localizer,
                ),
              if (_loadingRelations) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(localizer.cancel),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : () => _submitDialog(setModalState),
          child: Text(_editing == null ? localizer.create : localizer.save),
        ),
      ],
    );
  }

  Widget _buildRelationPicker({
    required String title,
    required List<RelationOption> options,
    required Set<int> selectedIds,
    required RelationToggleCallback onToggle,
    required AppLocalizations localizer,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 160),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: options.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(localizer.noOptions),
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  children: options.map((option) {
                    return CheckboxListTile(
                      dense: true,
                      value: selectedIds.contains(option.id),
                      title: Text(option.name),
                      onChanged: (checked) =>
                          onToggle(option.id, selected: checked ?? false),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final session = authState is AuthAuthenticated ? authState.session : null;
    final isEmployeeOnly = (session?.hasRole('Employee') ?? false) &&
        session?.hasRole('Admin') != true &&
        session?.hasRole('SuperAdmin') != true;

    return Scaffold(
      appBar: AppBar(title: Text(localizer.consultations)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        icon: const Icon(Icons.add),
        label: Text(localizer.create),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEmployeeOnly
                      ? localizer.myConsultations
                      : localizer.consultationManagement,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: localizer.search,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                              context
                                  .read<ConsultationsBloc>()
                                  .add(LoadConsultations());
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () => context
                              .read<ConsultationsBloc>()
                              .add(SearchConsultations(_searchController.text)),
                        ),
                      ],
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (v) => context.read<ConsultationsBloc>().add(
                        SearchConsultations(v),
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isEmployeeOnly
                        ? Colors.blue.withValues(alpha: 0.08)
                        : Colors.orange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isEmployeeOnly
                        ? localizer.consultationEmployeeHint
                        : localizer.consultationAssignmentHint,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<ConsultationsBloc, ConsultationsState>(
              listener: (context, state) {
                if (state is ConsultationsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${localizer.error}: ${state.message}'),),
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
                  return Center(
                      child: Text('${localizer.error}: ${state.message}'),);
                }
                if (state is ConsultationsLoaded) {
                  final items = state.consultations;
                  if (items.isEmpty) {
                    return Center(child: Text(localizer.noData));
                  }
                  return RefreshIndicator(
                    onRefresh: () async => context
                        .read<ConsultationsBloc>()
                        .add(RefreshConsultations()),
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          title: Text(item.subject),
                          subtitle: Text(
                              '${item.type} - ${item.status} - ${item.consultationDate.toLocal().toString().substring(0, 16)}',),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => ConsultationDetailScreen(
                                  consultation: item,
                                ),
                              ),
                            );
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _openEditDialog(item);
                              } else if (value == 'delete') {
                                _confirmDelete(item);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(localizer.edit),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(localizer.delete),
                              ),
                            ],
                          ),
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
