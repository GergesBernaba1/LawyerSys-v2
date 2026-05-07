import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/calendar/bloc/calendar_bloc.dart';
import 'package:qadaya_lawyersys/features/calendar/bloc/calendar_event.dart' as bloc_event;
import 'package:qadaya_lawyersys/features/calendar/bloc/calendar_state.dart';
import 'package:qadaya_lawyersys/features/calendar/models/calendar_event.dart';

class CalendarEventFormScreen extends StatefulWidget {

  const CalendarEventFormScreen({
    super.key,
    this.event,
    required this.fromDate,
    required this.toDate,
  });
  final CalendarEvent? event;
  final String fromDate;
  final String toDate;

  @override
  State<CalendarEventFormScreen> createState() =>
      _CalendarEventFormScreenState();
}

class _CalendarEventFormScreenState extends State<CalendarEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _typeController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _isReminderEvent = false;
  bool _isSaving = false;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.event!;
      _titleController.text = e.title;
      _typeController.text = e.type;
      _notesController.text = e.notes ?? '';
      _isReminderEvent = e.isReminderEvent;
      try {
        final parsed = DateTime.parse(e.start);
        _startDate = parsed;
        _startTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      } catch (_) {}
      if (e.end != null) {
        try {
          final parsedEnd = DateTime.parse(e.end!);
          _endDate = parsedEnd;
          _endTime = TimeOfDay(hour: parsedEnd.hour, minute: parsedEnd.minute);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _typeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : (_endDate ?? _startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : (_endTime ?? _startTime);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _buildIso(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute)
        .toIso8601String();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final data = {
      'title': _titleController.text.trim(),
      'type': _typeController.text.trim(),
      'start': _buildIso(_startDate, _startTime),
      if (_endDate != null && _endTime != null)
        'end': _buildIso(_endDate!, _endTime!),
      'notes': _notesController.text.trim(),
      'isReminderEvent': _isReminderEvent,
    };

    if (_isEditing) {
      context.read<CalendarBloc>().add(bloc_event.UpdateCalendarEvent(
            widget.event!.id,
            data,
            fromDate: widget.fromDate,
            toDate: widget.toDate,
          ),);
    } else {
      context.read<CalendarBloc>().add(bloc_event.CreateCalendarEvent(
            data,
            fromDate: widget.fromDate,
            toDate: widget.toDate,
          ),);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
          title:
              Text(_isEditing ? l.editCalendarEvent : l.createCalendarEvent),),
      body: BlocListener<CalendarBloc, CalendarState>(
        listener: (context, state) {
          if (state is CalendarOperationSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
            Navigator.of(context).pop(true);
          }
          if (state is CalendarError) {
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
                        controller: _titleController,
                        decoration: InputDecoration(
                            labelText: l.calendarEventTitle,
                            border: const OutlineInputBorder(),),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l.allFieldsAreRequired
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _typeController,
                        decoration: InputDecoration(
                            labelText: l.calendarEventType,
                            border: const OutlineInputBorder(),),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l.allFieldsAreRequired
                            : null,
                      ),
                      const SizedBox(height: 12),
                      // Start date/time
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickDate(true),
                              child: Text(
                                  '${l.startDate}: ${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickTime(true),
                              child: Text(
                                  '${l.timeEntries}: ${_startTime.format(context)}',),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // End date/time (optional)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickDate(false),
                              child: Text(_endDate == null
                                  ? l.calendarEventEndOptional
                                  : '${l.calendarEventEnd}: ${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}',),
                            ),
                          ),
                          if (_endDate != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _pickTime(false),
                                child: Text(
                                    '${l.timeEntries}: ${_endTime?.format(context) ?? ''}',),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                            labelText: l.notes,
                            border: const OutlineInputBorder(),),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: Text(l.calendarReminderEvent),
                        value: _isReminderEvent,
                        onChanged: (v) =>
                            setState(() => _isReminderEvent = v),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _submit, child: Text(l.save)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
