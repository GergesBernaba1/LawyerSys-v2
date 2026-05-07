import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/customers_bloc.dart';
import '../bloc/customers_event.dart';
import '../bloc/customers_state.dart';
import '../models/customer.dart';
import '../repositories/customers_repository.dart';

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
  File? _selectedImage;
  bool _isUploadingImage = false;

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
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
        listener: (context, state) async {
          // Capture context-dependent objects before any async gap.
          final messenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);
          final repository = RepositoryProvider.of<CustomersRepository>(context);

          if (state is CustomerOperationSuccess) {
            final customerId =
                state.customerId ?? widget.customer?.customerId ?? '';
            if (_selectedImage != null && customerId.isNotEmpty) {
              setState(() => _isUploadingImage = true);
              try {
                await repository.uploadProfileImage(customerId, _selectedImage!.path);
              } catch (_) {
                // Non-fatal: profile image upload failed
              } finally {
                if (mounted) setState(() => _isUploadingImage = false);
              }
            }
            if (!mounted) return;
            messenger.showSnackBar(SnackBar(content: Text(l.customerSaved)));
            navigator.pop(true);
          }
          if (state is CustomersError) {
            setState(() => _isSaving = false);
            if (!mounted) return;
            messenger.showSnackBar(
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
                      // Profile image picker
                      GestureDetector(
                        onTap: _isUploadingImage ? null : _pickImage,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                          child: _selectedImage == null
                              ? Icon(Icons.add_a_photo,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.primary)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
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
