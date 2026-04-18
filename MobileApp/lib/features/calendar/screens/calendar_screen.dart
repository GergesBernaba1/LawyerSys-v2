import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';
import '../models/calendar_event.dart' as model_calendar_event;
import '../../../core/localization/app_localizations.dart';

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
    final fromDate = _getFromDate(_view, _anchorDate);
    final toDate = _getToDate(_view, _anchorDate);
    context.read<CalendarBloc>().add(
      LoadCalendarEvents(fromDate: fromDate, toDate: toDate),
    );
  }

  String _getFromDate(String view, DateTime anchorDate) {
    final base = DateTime(anchorDate.year, anchorDate.month, anchorDate.day);
    if (view == 'week') {
      final start = DateTime(base.year, base.month, base.day - base.weekday + 1);
      return _toDateOnly(start);
    }
    // Month view
    final start = DateTime(base.year, base.month, 1);
    return _toDateOnly(start);
  }

  String _getToDate(String view, DateTime anchorDate) {
    final base = DateTime(anchorDate.year, anchorDate.month, anchorDate.day);
    if (view == 'week') {
      final weekStart = DateTime(base.year, base.month, base.day - base.weekday + 1);
      final end = weekStart.add(const Duration(days: 6));
      return _toDateOnly(end);
    }
    // Month view
    final end = DateTime(base.year, base.month + 1, 0);
    return _toDateOnly(end);
  }

  String _toDateOnly(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizer.calendar),
      ),
      body: BlocBuilder<CalendarBloc, CalendarState>(
        builder: (context, state) {
          if (state is CalendarLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CalendarError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is CalendarLoaded) {
            final events = state.events;
            
            // Group events by date
            final Map<String, List<model_calendar_event.CalendarEvent>> groupedByDate = {};
            for (final event in events) {
              final dateKey = event.start.substring(0, 10); // YYYY-MM-DD
              if (!groupedByDate.containsKey(dateKey)) {
                groupedByDate[dateKey] = [];
              }
              groupedByDate[dateKey]!.add(event);
            }
            
            // Sort dates
            final sortedDates = groupedByDate.keys.toList()..sort();
            
            return ListView(
              children: [
                // Header controls
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            localizer.calendar,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // View selector
                          DropdownButton<String>(
                            value: _view,
                            items: const [
                              DropdownMenuItem(
                                value: 'month',
                                child: Text('Monthly'),
                              ),
                              DropdownMenuItem(
                                value: 'week',
                                child: Text('Weekly'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _view = value;
                                  _loadCalendarEvents();
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          // Date selector
                          TextButton(
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _anchorDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null && mounted) {
                                setState(() {
                                  _anchorDate = picked;
                                  _loadCalendarEvents();
                                });
                              }
                            },
                            child: Text(
                              '${_anchorDate.year}-${_anchorDate.month.toString().padLeft(2, '0')}-${_anchorDate.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Events display
                if (sortedDates.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No events found'),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final dayEvents = groupedByDate[date] ?? [];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ExpansionTile(
                          title: Text(
                            DateTime.parse(date).toLocal().toIso8601String().split('T').first,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          children: dayEvents.map((event) => ListTile(
                            leading: Container(
                              width: 4,
                              height: 24,
                              color: event.isReminderEvent ? Colors.orange : Colors.blue,
                            ),
                            title: Text(event.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${event.type} • ${_formatTime(event.start)}'),
                                if (event.notes != null && event.notes!.isNotEmpty)
                                  Text(event.notes!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                            trailing: event.caseCode != null
                                ? IconButton(
                                    icon: const Icon(Icons.description),
                                    tooltip: 'View Case',
                                    onPressed: () {},
                                  )
                                : null,
                          )).toList(),
                        ),
                      );
                    },
                  ),
              ],
            );
          }
          return const Center(child: Text('No data available'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add event functionality coming soon')),
          );
        },
        tooltip: 'Add Event',
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.toLocal().hour.toString().padLeft(2, '0')}:${dateTime.toLocal().minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}