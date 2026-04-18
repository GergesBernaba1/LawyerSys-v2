import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/contenders_bloc.dart';
import '../bloc/contenders_event.dart';
import '../bloc/contenders_state.dart';
import '../models/contender.dart';

class ContenderFormScreen extends StatefulWidget {
  final ContenderModel? contender;

  const ContenderFormScreen({super.key, this.contender});

  @override
  State<ContenderFormScreen> createState() => _ContenderFormScreenState();
}

class _ContenderFormScreenState extends State<ContenderFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _ssnController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _typeController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.contender != null) {
      _fullNameController.text = widget.contender!.fullName;
      _ssnController.text = widget.contender!.ssn;
      _phoneController.text = widget.contender!.phone;
      _emailController.text = widget.contender!.email;
      _addressController.text = widget.contender!.address;
      _typeController.text = widget.contender!.contenderType;
      _notesController.text = widget.contender!.notes;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ssnController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _typeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final contender = ContenderModel(
      contenderId: widget.contender?.contenderId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: _fullNameController.text.trim(),
      ssn: _ssnController.text.trim(),
      birthDate: widget.contender?.birthDate,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      contenderType: _typeController.text.trim(),
      notes: _notesController.text.trim(),
    );

    final bloc = context.read<ContendersBloc>();
    if (widget.contender == null) {
      bloc.add(CreateContender(contender));
    } else {
      bloc.add(UpdateContender(contender));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;
    final isEdit = widget.contender != null;

    return BlocListener<ContendersBloc, ContendersState>(
      listener: (context, state) {
        if (state is ContenderOperationSuccess) {
          Navigator.pop(context);
        }
        if (state is ContendersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${localizer.error}: ${state.message}')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(isEdit ? localizer.edit : localizer.add)),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(labelText: localizer.fullName),
                  validator: (value) => value == null || value.isEmpty ? localizer.allFieldsAreRequired : null,
                ),
                TextFormField(
                  controller: _ssnController,
                  decoration: InputDecoration(labelText: localizer.ssn),
                  validator: (value) => value == null || value.isEmpty ? localizer.allFieldsAreRequired : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: localizer.phone),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: localizer.email),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: localizer.address),
                ),
                TextFormField(
                  controller: _typeController,
                  decoration: InputDecoration(labelText: localizer.caseType),
                ),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(labelText: localizer.notes),
                  maxLines: 3,
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
      ),
    );
  }
}
