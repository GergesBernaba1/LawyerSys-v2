import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/trust_accounting_bloc.dart';
import '../bloc/trust_accounting_event.dart';
import '../models/trust_transaction.dart';

class TrustFormScreen extends StatefulWidget {
  final TrustTransactionModel? transaction;

  const TrustFormScreen({super.key, this.transaction});

  @override
  State<TrustFormScreen> createState() => _TrustFormScreenState();
}

class _TrustFormScreenState extends State<TrustFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _caseController = TextEditingController();
  final _accountController = TextEditingController();
  final _typeController = TextEditingController();
  final _amountController = TextEditingController();
  final _statusController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    if (t != null) {
      _caseController.text = t.caseId;
      _accountController.text = t.accountId;
      _typeController.text = t.transactionType;
      _amountController.text = t.amount.toString();
      _statusController.text = t.status;
      _notesController.text = t.notes;
      _selectedDate = t.date;
    }
  }

  @override
  void dispose() {
    _caseController.dispose();
    _accountController.dispose();
    _typeController.dispose();
    _amountController.dispose();
    _statusController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final transaction = TrustTransactionModel(
      transactionId: widget.transaction?.transactionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      caseId: _caseController.text.trim(),
      accountId: _accountController.text.trim(),
      date: _selectedDate,
      transactionType: _typeController.text.trim(),
      amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
      status: _statusController.text.trim(),
      notes: _notesController.text.trim(),
    );

    final bloc = context.read<TrustAccountingBloc>();
    if (widget.transaction == null) {
      bloc.add(CreateTrustTransaction(transaction));
    } else {
      bloc.add(UpdateTrustTransaction(transaction));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);
    final isEdit = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? localizer.edit : localizer.add)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _caseController,
                decoration: InputDecoration(labelText: localizer.caseCode),
                validator: (value) => value == null || value.isEmpty ? localizer.allFieldsAreRequired : null,
              ),
              TextFormField(
                controller: _accountController,
                decoration: InputDecoration(labelText: localizer.accountId),
                validator: (value) => value == null || value.isEmpty ? localizer.allFieldsAreRequired : null,
              ),
              TextFormField(
                controller: _typeController,
                decoration: InputDecoration(labelText: localizer.transactionType),
                validator: (value) => value == null || value.isEmpty ? localizer.allFieldsAreRequired : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: localizer.amount),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value == null || value.isEmpty ? localizer.allFieldsAreRequired : null,
              ),
              TextFormField(
                controller: _statusController,
                decoration: InputDecoration(labelText: localizer.status),
                validator: (value) => value == null || value.isEmpty ? localizer.allFieldsAreRequired : null,
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: _pickDate, child: Text('${localizer.dateLabel}: ${_selectedDate.toLocal().toIso8601String().split('T').first}')),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(labelText: localizer.notes),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: Text(isEdit ? localizer.save : localizer.create)),
            ],
          ),
        ),
      ),
    );
  }
}
