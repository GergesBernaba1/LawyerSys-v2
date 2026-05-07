import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/customers/bloc/customers_bloc.dart';
import 'package:qadaya_lawyersys/features/customers/bloc/customers_event.dart';
import 'package:qadaya_lawyersys/features/customers/bloc/customers_state.dart';

class PaymentProofSubmissionScreen extends StatefulWidget {

  const PaymentProofSubmissionScreen({super.key, required this.caseCode});
  final int caseCode;

  @override
  State<PaymentProofSubmissionScreen> createState() =>
      _PaymentProofSubmissionScreenState();
}

class _PaymentProofSubmissionScreenState
    extends State<PaymentProofSubmissionScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _filePathController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _filePathController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submitProof() {
    final amount = double.tryParse(_amountController.text.trim());
    final filePath = _filePathController.text.trim();
    final localizer = AppLocalizations.of(context)!;

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizer.error)),
      );
      return;
    }

    if (filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizer.pleaseSelectFile)),
      );
      return;
    }

    context.read<CustomersBloc>().add(SubmitPaymentProof(
          caseCode: widget.caseCode,
          amount: amount,
          paymentDate: _selectedDate,
          filePath: filePath,
          notes: _notesController.text.trim(),
        ),);
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizer.submitPaymentProof)),
      body: BlocListener<CustomersBloc, CustomersState>(
        listener: (context, state) {
          if (state is PaymentProofSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(localizer.paymentProofSubmitted)),
            );
            Navigator.pop(context, true);
          } else if (state is CustomersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${localizer.error}: ${state.message}')),
            );
          }
        },
        child: BlocBuilder<CustomersBloc, CustomersState>(
          builder: (context, state) {
            final isSubmitting = state is PaymentProofSubmitting;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Case #${widget.caseCode}',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: localizer.amount,
                      prefixText: r'$ ',
                      border: const OutlineInputBorder(),
                    ),
                    enabled: !isSubmitting,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(localizer.paymentDate),
                    subtitle: Text(
                      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: isSubmitting ? null : _selectDate,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _filePathController,
                    decoration: InputDecoration(
                      labelText: localizer.proofFilePath,
                      hintText: '/storage/emulated/0/Documents/receipt.pdf',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.folder_open),
                        onPressed: isSubmitting ? null : () {},
                      ),
                    ),
                    enabled: !isSubmitting,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: localizer.notesOptional,
                      border: const OutlineInputBorder(),
                    ),
                    enabled: !isSubmitting,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: isSubmitting ? null : _submitProof,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload),
                    label: Text(isSubmitting ? localizer.submitting : localizer.submit),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
