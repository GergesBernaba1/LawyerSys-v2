import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/calendar/bloc/calendar_bloc.dart';
import 'package:qadaya_lawyersys/features/calendar/bloc/calendar_event.dart';
import 'package:qadaya_lawyersys/features/calendar/bloc/calendar_state.dart';
import 'package:qadaya_lawyersys/features/calendar/models/calendar_event.dart' as model;
import 'package:qadaya_lawyersys/features/calendar/screens/calendar_event_form_screen.dart';

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
    return _toDateOnly(DateTime(base.year, base.month));
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

  Future<void> _confirmDelete(
      model.CalendarEvent event, AppLocalizations l,) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteCalendarEvent),
        content: Text(l.deleteCalendarEventConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.delete),),
        ],
      ),
    );
    if ((confirmed ?? false) && mounted) {
      context.read<CalendarBloc>().add(
            DeleteCalendarEvent(event.id,
                fromDate: _fromDate, toDate: _toDate,),
          );
    }
  }

  void _showDayEventsSheet(
      BuildContext context, String date, List<model.CalendarEvent> dayEvents,) {
    final l = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          expand: false,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (_, scrollController) {
            return Column(
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                // Date header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${dayEvents.length} ${l.noEventsFound.replaceAll('No events found', dayEvents.length == 1 ? 'event' : 'events')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Event list
                Expanded(
                  child: dayEvents.isEmpty
                      ? Center(child: Text(l.noEventsFound))
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: dayEvents.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 16, endIndent: 16),
                          itemBuilder: (ctx, index) {
                            final event = dayEvents[index];
                            final timeRange = event.end != null
                                ? '${_formatTime(event.start)} – ${_formatTime(event.end!)}'
                                : _formatTime(event.start);
                            return ListTile(
                              leading: Container(
                                width: 4,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: event.isReminderEvent
                                      ? Colors.orange
                                      : Colors.blue,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(event.title)),
                                  if (event.isReminderEvent)
                                    Container(
                                      margin: const EdgeInsetsDirectional.only(start: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2,),
                                      decoration: BoxDecoration(
                                        color: Colors.orange
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.orange
                                                .withValues(alpha: 0.5),),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.notifications,
                                              size: 12, color: Colors.orange,),
                                          const SizedBox(width: 2),
                                          Text(
                                            l.calendarReminderEvent,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.orange,),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text('${event.type} • $timeRange'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        size: 20,),
                                    tooltip: l.edit,
                                    onPressed: () {
                                      Navigator.pop(sheetCtx);
                                      _openForm(event: event);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        size: 20, color: Colors.red,),
                                    tooltip: l.delete,
                                    onPressed: () async {
                                      Navigator.pop(sheetCtx);
                                      await _confirmDelete(event, l);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
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
                SnackBar(content: Text('${l.error}: ${state.message}')),);
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
                              value: 'month', child: Text(l.calendarView),),
                          DropdownMenuItem(
                              value: 'week', child: Text(l.listView),),
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
                            '${_anchorDate.year}-${_anchorDate.month.toString().padLeft(2, '0')}',),
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
                                    horizontal: 12, vertical: 6,),
                                child: ExpansionTile(
                                  title: InkWell(
                                    onTap: () => _showDayEventsSheet(
                                        context, date, dayEvents,),
                                    child: Text(date,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,),),
                                  ),
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
                                                '${event.type} • ${_formatTime(event.start)}',),
                                            onTap: () => _showDayEventsSheet(
                                                context, date, dayEvents,),
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
                                                    child: Text(l.edit),),
                                                PopupMenuItem(
                                                    value: 'delete',
                                                    child: Text(l.delete),),
                                              ],
                                            ),
                                          ),)
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
