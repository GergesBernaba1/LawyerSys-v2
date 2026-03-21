import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/hearings_bloc.dart';
import '../bloc/hearings_event.dart';
import '../models/hearing.dart';

class HearingFormScreen extends StatefulWidget {
  final Hearing? hearing;

  const HearingFormScreen({super.key, this.hearing});

  @override
  State<HearingFormScreen> createState() => _HearingFormScreenState();
}

class _HearingFormScreenState extends State<HearingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _caseNumberController = TextEditingController();
  final _judgeNameController = TextEditingController();
  final _courtLocationController = TextEditingController();
  final _notesController = TextEditingController();
  final _notificationController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.hearing != null) {
      _caseNumberController.text = widget.hearing!.caseNumber;
      _judgeNameController.text = widget.hearing!.judgeName;
      _courtLocationController.text = widget.hearing!.courtLocation;
      _notesController.text = widget.hearing!.notes ?? '';
      _notificationController.text = widget.hearing!.hearingNotificationDetails ?? '';
      _selectedDate = widget.hearing!.hearingDate;
      _selectedTime = TimeOfDay(hour: widget.hearing!.hearingDate.hour, minute: widget.hearing!.hearingDate.minute);
    }
  }

  @override
  void dispose() {
    _caseNumberController.dispose();
    _judgeNameController.dispose();
    _courtLocationController.dispose();
    _notesController.dispose();
    _notificationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final hearingDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final hearing = Hearing(
      hearingId: widget.hearing?.hearingId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      tenantId: widget.hearing?.tenantId ?? '',
      hearingDate: hearingDate,
      caseId: widget.hearing?.caseId ?? '',
      caseNumber: _caseNumberController.text.trim(),
      judgeName: _judgeNameController.text.trim(),
      courtId: widget.hearing?.courtId ?? '',
      courtName: widget.hearing?.courtName ?? '',
      courtLocation: _courtLocationController.text.trim(),
      hearingNotificationDetails: _notificationController.text.trim().isEmpty ? null : _notificationController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      lastSyncedAt: DateTime.now(),
      isDirty: true,
    );

    if (widget.hearing == null) {
      context.read<HearingsBloc>().add(CreateHearing(hearing));
    } else {
      context.read<HearingsBloc>().add(UpdateHearing(hearing));
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);
    final isEditing = widget.hearing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? localizer.editHearing : localizer.createHearing)),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _caseNumberController,
                      decoration: InputDecoration(labelText: localizer.caseNumber, border: const OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? localizer.allFieldsAreRequired : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _judgeNameController,
                      decoration: InputDecoration(labelText: localizer.judgeLabel, border: const OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? localizer.allFieldsAreRequired : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _courtLocationController,
                      decoration: InputDecoration(labelText: localizer.courtLocation, border: const OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? localizer.allFieldsAreRequired : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notificationController,
                      decoration: InputDecoration(labelText: localizer.notificationDetails, border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: localizer.notes, border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickDate,
                            child: Text('${localizer.dateLabel}: ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickTime,
                            child: Text('${localizer.timeEntries}: ${_selectedTime.format(context)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(isEditing ? localizer.save : localizer.save),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
