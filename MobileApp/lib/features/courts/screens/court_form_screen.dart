import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/courts/bloc/courts_bloc.dart';
import 'package:qadaya_lawyersys/features/courts/bloc/courts_event.dart';
import 'package:qadaya_lawyersys/features/courts/bloc/courts_state.dart';
import 'package:qadaya_lawyersys/features/courts/models/court.dart';

class CourtFormScreen extends StatefulWidget {

  const CourtFormScreen({super.key, this.court});
  final CourtModel? court;

  @override
  State<CourtFormScreen> createState() => _CourtFormScreenState();
}

class _CourtFormScreenState extends State<CourtFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _governorateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  bool get _isEditing => widget.court != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.court!.name;
      _addressController.text = widget.court!.address;
      _governorateController.text = widget.court!.governorate;
      _phoneController.text = widget.court!.phone;
      _notesController.text = widget.court!.notes;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _governorateController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final court = CourtModel(
      courtId: widget.court?.courtId ?? '',
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      governorate: _governorateController.text.trim(),
      phone: _phoneController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (_isEditing) {
      context.read<CourtsBloc>().add(UpdateCourt(court));
    } else {
      context.read<CourtsBloc>().add(CreateCourt(court));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? l.editCourt : l.createCourt)),
      body: BlocListener<CourtsBloc, CourtsState>(
        listener: (context, state) {
          if (state is CourtOperationSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l.courtSaved)));
            Navigator.of(context).pop(true);
          }
          if (state is CourtsError) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${l.error}: ${state.message}')),);
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
                        controller: _nameController,
                        decoration: InputDecoration(
                            labelText: l.courtName,
                            border: const OutlineInputBorder(),),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l.allFieldsAreRequired : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                            labelText: l.address,
                            border: const OutlineInputBorder(),),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l.allFieldsAreRequired : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _governorateController,
                        decoration: InputDecoration(
                            labelText: l.governorate,
                            border: const OutlineInputBorder(),),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l.allFieldsAreRequired : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                            labelText: l.phone,
                            border: const OutlineInputBorder(),),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                            labelText: l.notes,
                            border: const OutlineInputBorder(),),
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
