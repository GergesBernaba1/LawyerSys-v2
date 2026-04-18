import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';
import '../models/calendar_event.dart' as model;
import '../../../core/localization/app_localizations.dart';
import 'calendar_event_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String _view = 'month';
  DateTime _anchorDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCalendarEvents();
  }

  void _loadCalendarEvents() {
    context.read<CalendarBloc>().add(
          LoadCalendarEvents(
            fromDate: _getFromDate(_view, _anchorDate),
            toDate: _getToDate(_view, _anchorDate),
          ),
        );
  }

  String get _fromDate => _getFromDate(_view, _anchorDate);
  String get _toDate => _getToDate(_view, _anchorDate);

  String _getFromDate(String view, DateTime anchorDate) {
    final base = DateTime(anchorDate.year, anchorDate.month, anchorDate.day);
    if (view == 'week') {
      final start =
          DateTime(base.year, base.month, base.day - base.weekday + 1);
      return _toDateOnly(start);
    }
    return _toDateOnly(DateTime(base.year, base.month, 1));
  }

  String _getToDate(String view, DateTime anchorDate) {
    final base = DateTime(anchorDate.year, anchorDate.month, anchorDate.day);
    if (view == 'week') {
      final weekStart =
          DateTime(base.year, base.month, base.day - base.weekday + 1);
      return _toDateOnly(weekStart.add(const Duration(days: 6)));
    }
    return _toDateOnly(DateTime(base.year, base.month + 1, 0));
  }

  String _toDateOnly(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _formatTime(String s) {
    try {
      final dt = DateTime.parse(s);
      return '${dt.toLocal().hour.toString().padLeft(2, '0')}:${dt.toLocal().minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return s;
    }
  }

  Future<void> _openForm({model.CalendarEvent? event}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CalendarEventFormScreen(
          event: event,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      ),
    );
    if (result == true && mounted) _loadCalendarEvents();
  }

  Future<void> _confirmDelete(model.CalendarEvent event, AppLocalizations l) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteCalendarEvent),
        content: Text(l.deleteCalendarEventConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.delete)),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<CalendarBloc>().add(
            DeleteCalendarEvent(event.id,
                fromDate: _fromDate, toDate: _toDate),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.calendar)),
      floatingActionButton: FloatingActionButton(
        tooltip: l.createCalendarEvent,
        onPressed: _openForm,
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<CalendarBloc, CalendarState>(
        listener: (context, state) {
          if (state is CalendarOperationSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is CalendarError) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${l.error}: ${state.message}')));
          }
        },
        builder: (context, state) {
          if (state is CalendarLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CalendarError) {
            return Center(child: Text('${l.error}: ${state.message}'));
          }
          if (state is CalendarLoaded) {
            final events = state.events;

            final Map<String, List<model.CalendarEvent>> grouped = {};
            for (final e in events) {
              final key = e.start.substring(0, 10);
              grouped.putIfAbsent(key, () => []).add(e);
            }
            final sortedDates = grouped.keys.toList()..sort();

            return Column(
              children: [
                // Controls
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButton<String>(
                        value: _view,
                        items: [
                          DropdownMenuItem(
                              value: 'month', child: Text(l.calendarView)),
                          DropdownMenuItem(
                              value: 'week', child: Text(l.listView)),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _view = v);
                            _loadCalendarEvents();
                          }
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                            '${_anchorDate.year}-${_anchorDate.month.toString().padLeft(2, '0')}'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _anchorDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null && mounted) {
                            setState(() => _anchorDate = picked);
                            _loadCalendarEvents();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // Event list
                Expanded(
                  child: sortedDates.isEmpty
                      ? Center(child: Text(l.noEventsFound))
                      : RefreshIndicator(
                          onRefresh: () async => _loadCalendarEvents(),
                          child: ListView.builder(
                            itemCount: sortedDates.length,
                            itemBuilder: (context, i) {
                              final date = sortedDates[i];
                              final dayEvents = grouped[date]!;
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: ExpansionTile(
                                  title: Text(date,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  initiallyExpanded: true,
                                  children: dayEvents
                                      .map((event) => ListTile(
                                            leading: Container(
                                              width: 4,
                                              height: 36,
                                              color: event.isReminderEvent
                                                  ? Colors.orange
                                                  : Colors.blue,
                                            ),
                                            title: Text(event.title),
                                            subtitle: Text(
                                                '${event.type} • ${_formatTime(event.start)}'),
                                            trailing: PopupMenuButton<String>(
                                              onSelected: (v) {
                                                if (v == 'edit') {
                                                  _openForm(event: event);
                                                } else if (v == 'delete') {
                                                  _confirmDelete(event, l);
                                                }
                                              },
                                              itemBuilder: (_) => [
                                                PopupMenuItem(
                                                    value: 'edit',
                                                    child: Text(l.edit)),
                                                PopupMenuItem(
                                                    value: 'delete',
                                                    child: Text(l.delete)),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          }
          return Center(child: Text(l.noDataAvailable));
        },
      ),
    );
  }
}
