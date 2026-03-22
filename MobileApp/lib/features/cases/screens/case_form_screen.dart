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
  final _caseNumberController = TextEditingController();
  final _caseTypeController = TextEditingController();
  final _statusController = TextEditingController();
  final _customerController = TextEditingController();
  final _courtController = TextEditingController();
  final _filingDateController = TextEditingController();
  final _closingDateController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.caseModel != null) {
      _caseNumberController.text = widget.caseModel!.caseNumber;
      _caseTypeController.text = widget.caseModel!.caseType;
      _statusController.text = widget.caseModel!.caseStatus;
      _customerController.text = widget.caseModel!.customerFullName;
      _courtController.text = widget.caseModel!.courtName;
      _filingDateController.text = widget.caseModel!.filingDate?.toIso8601String().split('T').first ?? '';
      _closingDateController.text = widget.caseModel!.closingDate?.toIso8601String().split('T').first ?? '';
    }
  }

  @override
  void dispose() {
    _caseNumberController.dispose();
    _caseTypeController.dispose();
    _statusController.dispose();
    _customerController.dispose();
    _courtController.dispose();
    _filingDateController.dispose();
    _closingDateController.dispose();
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
      controller.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final caseModel = CaseModel(
      caseId: widget.caseModel?.caseId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      tenantId: widget.caseModel?.tenantId ?? '',
      caseNumber: _caseNumberController.text,
      invitationType: widget.caseModel?.invitationType ?? 'Standard',
      caseStatus: _statusController.text,
      caseType: _caseTypeController.text,
      filingDate: _filingDateController.text.isEmpty ? null : DateTime.tryParse(_filingDateController.text),
      closingDate: _closingDateController.text.isEmpty ? null : DateTime.tryParse(_closingDateController.text),
      customerId: widget.caseModel?.customerId ?? '',
      customerFullName: _customerController.text,
      courtId: widget.caseModel?.courtId ?? '',
      courtName: _courtController.text,
      assignedEmployees: widget.caseModel?.assignedEmployees ?? [],
      lastSyncedAt: widget.caseModel?.lastSyncedAt,
      isDirty: true,
    );

    if (widget.caseModel == null) {
      context.read<CasesBloc>().add(CreateCase(caseModel));
    } else {
      context.read<CasesBloc>().add(UpdateCase(caseModel));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);
    final isEdit = widget.caseModel != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? localizer.edit : localizer.create),
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
                      controller: _caseNumberController,
                      decoration: InputDecoration(labelText: localizer.caseNumber, border: const OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? localizer.allFieldsAreRequired : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _caseTypeController,
                      decoration: InputDecoration(labelText: localizer.caseType, border: const OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? localizer.allFieldsAreRequired : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _statusController,
                      decoration: InputDecoration(labelText: localizer.status, border: const OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? localizer.allFieldsAreRequired : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customerController,
                      decoration: InputDecoration(labelText: localizer.customer, border: const OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? localizer.allFieldsAreRequired : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _courtController,
                      decoration: InputDecoration(labelText: localizer.court, border: const OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? localizer.allFieldsAreRequired : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _filingDateController,
                      readOnly: true,
                      decoration: InputDecoration(labelText: localizer.filingDate, border: const OutlineInputBorder()),
                      onTap: () => _pickDate(_filingDateController),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _closingDateController,
                      readOnly: true,
                      decoration: InputDecoration(labelText: localizer.closingDate, border: const OutlineInputBorder()),
                      onTap: () => _pickDate(_closingDateController),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(isEdit ? localizer.save : localizer.create),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
