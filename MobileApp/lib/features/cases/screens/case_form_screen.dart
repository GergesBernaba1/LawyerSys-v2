import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/cases_bloc.dart';
import '../bloc/cases_event.dart';
import '../models/case.dart';

class CaseFormScreen extends StatefulWidget {
  final CaseModel? caseModel;

  const CaseFormScreen({super.key, this.caseModel});

  @override
  State<CaseFormScreen> createState() => _CaseFormScreenState();
}

class _CaseFormScreenState extends State<CaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _typeController = TextEditingController();
  final _statementController = TextEditingController();
  final _dateController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final model = widget.caseModel;
    if (model != null) {
      _codeController.text = model.code.toString();
      _typeController.text = model.invitionType;
      _statementController.text = model.invitionsStatment;
      _dateController.text =
          model.invitionDate?.toIso8601String().split('T').first ?? '';
      _amountController.text = model.totalAmount.toString();
      _notesController.text = model.notes;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _typeController.dispose();
    _statementController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      controller.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final code = int.tryParse(_codeController.text.trim());
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (code == null || code <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Case code must be a positive number')));
      return;
    }

    setState(() => _isLoading = true);

    final existing = widget.caseModel;
    final model = CaseModel(
      id: existing?.id ?? 0,
      code: code,
      invitionsStatment: _statementController.text.trim(),
      invitionType: _typeController.text.trim(),
      invitionDate: _dateController.text.isEmpty
          ? null
          : DateTime.tryParse(_dateController.text),
      totalAmount: amount,
      notes: _notesController.text.trim(),
      status: existing?.status ?? 0,
      tenantId: existing?.tenantId ?? '',
      assignedEmployees: existing?.assignedEmployees ?? const [],
      lastSyncedAt: DateTime.now(),
      isDirty: true,
    );

    if (existing == null) {
      context.read<CasesBloc>().add(CreateCase(model));
    } else {
      context.read<CasesBloc>().add(UpdateCase(model));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;
    final isEdit = widget.caseModel != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? localizer.edit : localizer.createCase),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                          labelText: localizer.caseNumber,
                          border: const OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? localizer.allFieldsAreRequired
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _typeController,
                      decoration: InputDecoration(
                          labelText: localizer.caseType,
                          border: const OutlineInputBorder()),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? localizer.allFieldsAreRequired
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _statementController,
                      decoration: const InputDecoration(
                          labelText: 'Statement', border: OutlineInputBorder()),
                      minLines: 3,
                      maxLines: 5,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? localizer.allFieldsAreRequired
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                          labelText: localizer.dateLabel,
                          border: const OutlineInputBorder()),
                      onTap: () => _pickDate(_dateController),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? localizer.allFieldsAreRequired
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                          labelText: localizer.amount,
                          border: const OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? localizer.allFieldsAreRequired
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                          labelText: localizer.notes,
                          border: const OutlineInputBorder()),
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submit,
                      child:
                          Text(isEdit ? localizer.save : localizer.createCase),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
