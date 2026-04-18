import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/l10n/app_localizations.dart';
import '../bloc/governments_bloc.dart';
import '../bloc/governments_event.dart';
import '../bloc/governments_state.dart';
import '../models/government.dart';

class GovernmentFormScreen extends StatefulWidget {
  final Government? government;

  const GovernmentFormScreen({super.key, this.government});

  @override
  State<GovernmentFormScreen> createState() => _GovernmentFormScreenState();
}

class _GovernmentFormScreenState extends State<GovernmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSaving = false;

  bool get _isEditing => widget.government != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.government!.governorateName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final data = {'governorateName': _nameController.text.trim()};

    if (_isEditing) {
      context.read<GovernmentsBloc>().add(UpdateGovernment(widget.government!.governorateId, data));
    } else {
      context.read<GovernmentsBloc>().add(CreateGovernment(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? l.editGovernment : l.createGovernment)),
      body: BlocListener<GovernmentsBloc, GovernmentsState>(
        listener: (context, state) {
          if (state is GovernmentOperationSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l.governmentSaved)));
            Navigator.of(context).pop(true);
          }
          if (state is GovernmentsError) {
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
                        controller: _nameController,
                        decoration: InputDecoration(
                            labelText: l.governmentName,
                            border: const OutlineInputBorder()),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l.allFieldsAreRequired : null,
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
