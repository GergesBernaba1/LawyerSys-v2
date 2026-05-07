import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/hearings/bloc/hearings_bloc.dart';
import 'package:qadaya_lawyersys/features/hearings/bloc/hearings_event.dart';
import 'package:qadaya_lawyersys/features/hearings/bloc/hearings_state.dart';
import 'package:qadaya_lawyersys/features/hearings/models/hearing.dart';
import 'package:qadaya_lawyersys/features/hearings/screens/hearing_detail_screen.dart';
import 'package:qadaya_lawyersys/features/hearings/screens/hearing_form_screen.dart';
import 'package:qadaya_lawyersys/shared/widgets/skeleton_loader.dart';
import 'package:table_calendar/table_calendar.dart';

class HearingsListScreen extends StatefulWidget {
  const HearingsListScreen({super.key});

  @override
  State<HearingsListScreen> createState() => _HearingsListScreenState();
}

class _HearingsListScreenState extends State<HearingsListScreen> {
  final _searchController = TextEditingController();
  bool _calendarView = false;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<HearingsBloc>().add(LoadHearings());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Hearing> _eventsForDay(DateTime day, List<Hearing> hearings) {
    final target = DateTime(day.year, day.month, day.day);
    return hearings.where((h) {
      final d = DateTime(h.hearingDate.year, h.hearingDate.month, h.hearingDate.day);
      return d == target;
    }).toList();
  }

  String _formatDateTime(DateTime dateTime) {
    final date = dateTime.toLocal();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _hearingCard(Hearing hearing, AppLocalizations localizer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text('${localizer.caseNumber}: ${hearing.caseNumber}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${localizer.dateLabel}: ${_formatDateTime(hearing.hearingDate)}'),
            Text('${localizer.timeEntries}: ${hearing.hearingDate.toLocal().hour.toString().padLeft(2, '0')}:${hearing.hearingDate.toLocal().minute.toString().padLeft(2, '0')}'),
            Text('${localizer.judgeLabel}: ${hearing.judgeName}'),
            Text('${localizer.court}: ${hearing.courtLocation}'),
            if (hearing.notes != null && hearing.notes!.isNotEmpty) Text(hearing.notes!),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              final result = await Navigator.push<bool?>(
                context,
                MaterialPageRoute(builder: (_) => HearingFormScreen(hearing: hearing)),
              );
              if ((result ?? false) && mounted) {
                context.read<HearingsBloc>().add(LoadHearings());
              }
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(localizer.deleteHearing),
                  content: Text(localizer.deleteHearingConfirm),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(localizer.cancel)),
                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(localizer.delete)),
                  ],
                ),
              );
              if ((confirmed ?? false) && mounted) {
                context.read<HearingsBloc>().add(DeleteHearing(hearing.hearingId));
              }
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text(localizer.edit)),
            PopupMenuItem(value: 'delete', child: Text(localizer.delete)),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HearingDetailScreen(hearing: hearing)),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizer.hearings)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool?>(
            context,
            MaterialPageRoute(builder: (_) => const HearingFormScreen()),
          );
          if ((created ?? false) && context.mounted) {
            context.read<HearingsBloc>().add(LoadHearings());
          }
        },
        tooltip: localizer.addHearing,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: localizer.search,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    context.read<HearingsBloc>().add(SearchHearings(_searchController.text));
                  },
                ),
              ),
              onSubmitted: (value) {
                context.read<HearingsBloc>().add(SearchHearings(value));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                TextButton.icon(
                  icon: Icon(_calendarView ? Icons.list : Icons.calendar_today),
                  label: Text(_calendarView ? localizer.listView : localizer.calendarView),
                  onPressed: () {
                    setState(() {
                      _calendarView = !_calendarView;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocListener<HearingsBloc, HearingsState>(
              listener: (context, state) {
                if (state is HearingOperationSuccess) {
                  final snack = SnackBar(content: Text(state.message));
                  ScaffoldMessenger.of(context).showSnackBar(snack);
                }
                if (state is HearingsError) {
                  final snack = SnackBar(content: Text('${localizer.error}: ${state.message}'));
                  ScaffoldMessenger.of(context).showSnackBar(snack);
                }
              },
              child: BlocBuilder<HearingsBloc, HearingsState>(
                builder: (context, state) {
                  if (state is HearingsLoading) {
                    return const ListSkeleton(itemCount: 6);
                  }
                  if (state is HearingsError) {
                    return Center(child: Text('${localizer.error}: ${state.message}'));
                  }
                  if (state is HearingsLoaded) {
                  final hearings = state.hearings;
                  if (hearings.isEmpty) {
                    return Center(child: Text(localizer.noData));
                  }

                  if (_calendarView) {
                    final selectedDayEvents = _eventsForDay(_selectedDay, hearings);
                    return Column(
                      children: [
                        TableCalendar<Hearing>(
                          firstDay: DateTime.utc(2000),
                          lastDay: DateTime.utc(2100, 12, 31),
                          focusedDay: _focusedDay,
                          headerStyle: const HeaderStyle(formatButtonVisible: false),
                          calendarStyle: CalendarStyle(
                            markersMaxCount: 3,
                            markerDecoration: BoxDecoration(color: Colors.blue.shade700, shape: BoxShape.circle),
                          ),
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          eventLoader: (day) => _eventsForDay(day, hearings),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${localizer.dateLabel}: ${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (selectedDayEvents.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(localizer.noData),
                          )
                        else
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () async {
                                context.read<HearingsBloc>().add(RefreshHearings());
                              },
                              child: ListView.builder(
                                itemCount: selectedDayEvents.length,
                                itemBuilder: (context, index) {
                                  return _hearingCard(selectedDayEvents[index], localizer);
                                },
                              ),
                            ),
                          ),
                      ],
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<HearingsBloc>().add(RefreshHearings());
                    },
                    child: ListView.builder(
                      itemCount: hearings.length,
                      itemBuilder: (context, index) {
                        return _hearingCard(hearings[index], localizer);
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        ],
      ),
    );
  }
}


