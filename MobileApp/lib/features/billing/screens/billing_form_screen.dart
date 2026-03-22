import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/billing_bloc.dart';
import '../bloc/billing_event.dart';
import '../bloc/billing_state.dart';
import '../models/billing.dart';

class BillingFormScreen extends StatefulWidget {
  final bool isPayment; // true for payment, false for receipt

  const BillingFormScreen({
    super.key,
    required this.isPayment,
  });

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
    // Set default date to today
    final now = DateTime.now();
    _dateController.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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
        title: Text(widget.isPayment ? 'New Payment' : 'New Receipt'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<BillingBloc, BillingState>(
        listener: (context, state) {
          if (state is BillingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          } else if (state is BillingLoaded) {
            // Successfully loaded data after create/delete
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
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
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
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
                      builder: (context, state) {
                        List<DropdownMenuItem<int>> customerItems = [];
                        if (state is BillingLoaded) {
                          customerItems = state.customers
                              .map((customer) => DropdownMenuItem<int>(
                                    value: customer.id ?? 0,
                                    child: Text(
                                        customer.fullName ?? customer.email ?? 'Unknown'),
                                  ))
                              .toList();
                        }
                        return DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Customer',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _selectedCustomerId,
                          items: [
                            const DropdownMenuItem<int>(
                              value: 0,
                              child: Text('Select a customer'),
                            ),
                            ...customerItems
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCustomerId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value == 0) {
                              return 'Please select a customer';
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
                      builder: (context, state) {
                        List<DropdownMenuItem<int>> employeeItems = [];
                        if (state is BillingLoaded) {
                          employeeItems = state.employees
                              .map((employee) => DropdownMenuItem<int>(
                                    value: employee.id ?? 0,
                                    child: Text(
                                        employee.fullName ?? employee.email ?? 'Unknown'),
                                  ))
                              .toList();
                        }
                        return DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Employee',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _selectedEmployeeId,
                          items: [
                            const DropdownMenuItem<int>(
                              value: 0,
                              child: Text('Select an employee'),
                            ),
                            ...employeeItems
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedEmployeeId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value == 0) {
                              return 'Please select an employee';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(widget.isPayment ? 'Create Payment' : 'Create Receipt'),
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

    final amount = double.tryParse(_amountController.text) ?? 0;
    final date = _dateController.text;
    final notes = _notesController.text;

    if (widget.isPayment) {
      // Create payment
      final payment = BillingPay(
        amount: amount,
        dateOfOperation: date,
        notes: notes,
        customerId: _selectedCustomerId ?? 0,
        customerName: null, // Will be filled by backend or we could look it up
      );
      context.read<BillingBloc>().add(CreatePayment(payment));
    } else {
      // Create receipt
      final receipt = BillingReceipt(
        amount: amount,
        dateOfOperation: date,
        notes: notes,
        employeeId: _selectedEmployeeId ?? 0,
      );
      context.read<BillingBloc>().add(CreateReceipt(receipt));
    }
  }
}