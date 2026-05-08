import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/billing/bloc/billing_bloc.dart';
import 'package:qadaya_lawyersys/features/billing/bloc/billing_event.dart';
import 'package:qadaya_lawyersys/features/billing/bloc/billing_state.dart';
import 'package:qadaya_lawyersys/features/billing/models/billing.dart';

class BillingFormScreen extends StatefulWidget {

  const BillingFormScreen({
    super.key,
    required this.isPayment,
    this.initialPayment,
    this.initialReceipt,
  });
  final bool isPayment;
  final BillingPay? initialPayment;
  final BillingReceipt? initialReceipt;

  bool get isEditing =>
      (isPayment && initialPayment != null) ||
      (!isPayment && initialReceipt != null);

  @override
  State<BillingFormScreen> createState() => _BillingFormScreenState();
}

class _BillingFormScreenState extends State<BillingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  int? _selectedCustomerId;
  int? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      if (widget.isPayment && widget.initialPayment != null) {
        final p = widget.initialPayment!;
        _amountController.text = p.amount.toString();
        _dateController.text = p.dateOfOperation;
        _notesController.text = p.notes;
        _selectedCustomerId = p.customerId;
      } else if (!widget.isPayment && widget.initialReceipt != null) {
        final r = widget.initialReceipt!;
        _amountController.text = r.amount.toString();
        _dateController.text = r.dateOfOperation;
        _notesController.text = r.notes;
        _selectedEmployeeId = r.employeeId;
      }
    } else {
      final now = DateTime.now();
      _dateController.text =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Builder(builder: (ctx) {
          final l = AppLocalizations.of(ctx)!;
          if (widget.isEditing) {
            return Text(widget.isPayment ? l.editPayment : l.editReceipt);
          }
          return Text(widget.isPayment ? l.newPayment : l.newReceipt);
        },),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<BillingBloc, BillingState>(
        listener: (context, state) {
          final l = AppLocalizations.of(context)!;
          if (state is BillingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l.error}: ${state.message}')),
            );
          } else if (state is BillingLoaded) {
            // Successfully loaded data after create/delete
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          final l = AppLocalizations.of(context)!;
          if (state is BillingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: l.amount,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l.pleaseEnterAmount;
                      }
                      if (double.tryParse(value) == null) {
                        return l.pleaseEnterValidNumber;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: l.dateLabel,
                      border: const OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _dateController.text =
                              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (widget.isPayment)
                    // Payment form - customer selection
                    BlocBuilder<BillingBloc, BillingState>(
                      builder: (ctx, innerState) {
                        final lInner = AppLocalizations.of(ctx)!;
                        List<DropdownMenuItem<int>> customerItems = [];
                        if (innerState is BillingLoaded) {
                          customerItems = innerState.customers
                              .map((customer) => DropdownMenuItem<int>(
                                    value: customer.id ?? 0,
                                    child: Text(
                                        customer.fullName ?? customer.email ?? 'Unknown',),
                                  ),)
                              .toList();
                        }
                        return DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: lInner.customer,
                            border: const OutlineInputBorder(),
                          ),
                          initialValue: _selectedCustomerId,
                          items: [
                            DropdownMenuItem<int>(
                              value: 0,
                              child: Text(lInner.pleaseSelectCustomer),
                            ),
                            ...customerItems,
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCustomerId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value == 0) {
                              return lInner.pleaseSelectCustomer;
                            }
                            return null;
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  if (!widget.isPayment)
                    // Receipt form - employee selection
                    BlocBuilder<BillingBloc, BillingState>(
                      builder: (ctx, innerState) {
                        final lInner = AppLocalizations.of(ctx)!;
                        List<DropdownMenuItem<int>> employeeItems = [];
                        if (innerState is BillingLoaded) {
                          employeeItems = innerState.employees
                              .map((employee) => DropdownMenuItem<int>(
                                    value: employee.id ?? 0,
                                    child: Text(
                                        employee.fullName ?? employee.email ?? 'Unknown',),
                                  ),)
                              .toList();
                        }
                        return DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: lInner.employee,
                            border: const OutlineInputBorder(),
                          ),
                          initialValue: _selectedEmployeeId,
                          items: [
                            DropdownMenuItem<int>(
                              value: 0,
                              child: Text(lInner.pleaseSelectAnEmployee),
                            ),
                            ...employeeItems,
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedEmployeeId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value == 0) {
                              return lInner.pleaseSelectAnEmployee;
                            }
                            return null;
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: l.notes,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(widget.isEditing ? l.save : (widget.isPayment ? l.newPayment : l.newReceipt)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l = AppLocalizations.of(context)!;
    if (widget.isPayment && (_selectedCustomerId == null || _selectedCustomerId == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.pleaseSelectCustomer)),
      );
      return;
    }
    if (!widget.isPayment && (_selectedEmployeeId == null || _selectedEmployeeId == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.pleaseSelectAnEmployee)),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    final date = _dateController.text;
    final notes = _notesController.text;

    if (widget.isPayment) {
      final payment = BillingPay(
        id: widget.initialPayment?.id,
        amount: amount,
        dateOfOperation: date,
        notes: notes,
        customerId: _selectedCustomerId!,
      );
      if (widget.isEditing) {
        context.read<BillingBloc>().add(UpdatePayment(payment));
      } else {
        context.read<BillingBloc>().add(CreatePayment(payment));
      }
    } else {
      final receipt = BillingReceipt(
        id: widget.initialReceipt?.id,
        amount: amount,
        dateOfOperation: date,
        notes: notes,
        employeeId: _selectedEmployeeId!,
      );
      if (widget.isEditing) {
        context.read<BillingBloc>().add(UpdateReceipt(receipt));
      } else {
        context.read<BillingBloc>().add(CreateReceipt(receipt));
      }
    }
  }
}
