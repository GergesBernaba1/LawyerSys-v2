import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/timetracking_bloc.dart';
import '../bloc/timetracking_event.dart';
import '../bloc/timetracking_state.dart';

class TimeTrackingFormScreen extends StatefulWidget {
  const TimeTrackingFormScreen({super.key});

  @override
  State<TimeTrackingFormScreen> createState() => _TimeTrackingFormScreenState();
}

class _TimeTrackingFormScreenState extends State<TimeTrackingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedCaseCode;
  String _status = 'Stopped';

  @override
  void dispose() {
    _workTypeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizer.timeEntryForm),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<TimeTrackingBloc, TimeTrackingState>(
        listener: (context, state) {
          if (state is TimeTrackingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${localizer.error}: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          if (state is TimeTrackingLoading) {
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
                    controller: _workTypeController,
                    decoration: InputDecoration(
                      labelText: localizer.workTypeLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizer.pleaseEnterWorkType;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: localizer.description,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  // Case selection would come from bloc state
                  // For now, we'll use a simple text field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: localizer.caseCode,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _selectedCaseCode = int.tryParse(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: InputDecoration(
                      labelText: localizer.statusLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Stopped',
                        child: Text(localizer.stopped),
                      ),
                      DropdownMenuItem(
                        value: 'Running',
                        child: Text(localizer.running),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _status = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(localizer.save),
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

    context.read<TimeTrackingBloc>().add(StartTimeEntry(
      caseCode: _selectedCaseCode,
      workType: _workTypeController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      statusFilter: _status,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.timeEntrySaved)),
    );
    Navigator.pop(context);
  }
}