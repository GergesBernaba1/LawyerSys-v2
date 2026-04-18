import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/customers_bloc.dart';
import '../bloc/customers_event.dart';
import '../bloc/customers_state.dart';
import '../models/customer.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _ssnController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSaving = false;

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _fullNameController.text = widget.customer!.fullName;
      _phoneController.text = widget.customer!.phoneNumber ?? '';
      _emailController.text = widget.customer!.email ?? '';
      _ssnController.text = widget.customer!.ssn ?? '';
      _addressController.text = widget.customer!.address ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ssnController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final data = {
      'fullName': _fullNameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'ssn': _ssnController.text.trim(),
      'address': _addressController.text.trim(),
    };

    if (_isEditing) {
      context.read<CustomersBloc>().add(UpdateCustomer(widget.customer!.customerId, data));
    } else {
      context.read<CustomersBloc>().add(CreateCustomer(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? l.editCustomer : l.createCustomer)),
      body: BlocListener<CustomersBloc, CustomersState>(
        listener: (context, state) {
          if (state is CustomerOperationSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l.customerSaved)));
            Navigator.of(context).pop(true);
          }
          if (state is CustomersError) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${l.error}: ${state.message}')));
          }
        },
        child: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                            labelText: l.fullName,
                            border: const OutlineInputBorder()),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l.allFieldsAreRequired : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                            labelText: l.phoneNumber,
                            border: const OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                            labelText: l.email,
                            border: const OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ssnController,
                        decoration: InputDecoration(
                            labelText: l.ssn,
                            border: const OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                            labelText: l.address,
                            border: const OutlineInputBorder()),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submit,
                        child: Text(l.save),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
