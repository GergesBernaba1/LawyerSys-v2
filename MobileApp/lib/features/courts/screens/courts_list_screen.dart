import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/courts/bloc/courts_bloc.dart';
import 'package:qadaya_lawyersys/features/courts/bloc/courts_event.dart';
import 'package:qadaya_lawyersys/features/courts/bloc/courts_state.dart';
import 'package:qadaya_lawyersys/features/courts/models/court.dart';
import 'package:qadaya_lawyersys/features/courts/screens/court_detail_screen.dart';
import 'package:qadaya_lawyersys/features/courts/screens/court_form_screen.dart';

class CourtsListScreen extends StatefulWidget {
  const CourtsListScreen({super.key});

  @override
  State<CourtsListScreen> createState() => _CourtsListScreenState();
}

class _CourtsListScreenState extends State<CourtsListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CourtsBloc>().add(LoadCourts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(localizer.courts)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CourtFormScreen()));
          if (context.mounted) context.read<CourtsBloc>().add(RefreshCourts());
        },
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
                  onPressed: () => context.read<CourtsBloc>().add(SearchCourts(_searchController.text)),
                ),
              ),
              onSubmitted: (value) => context.read<CourtsBloc>().add(SearchCourts(value)),
            ),
          ),
          Expanded(
            child: BlocConsumer<CourtsBloc, CourtsState>(
              listener: (context, state) {
                if (state is CourtsError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${localizer.error}: ${state.message}')));
                }
                if (state is CourtOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                if (state is CourtsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CourtsError) {
                  return Center(child: Text('${localizer.error}: ${state.message}'));
                }
                if (state is CourtsLoaded) {
                  final courts = state.courts;
                  if (courts.isEmpty) {
                    return Center(child: Text(localizer.noCourtsFound));
                  }
                  return RefreshIndicator(
                    onRefresh: () async => context.read<CourtsBloc>().add(RefreshCourts()),
                    child: ListView.builder(
                      itemCount: courts.length,
                      itemBuilder: (context, index) {
                        final court = courts[index];
                        return ListTile(
                          title: Text(court.name),
                          subtitle: Text('${court.governorate} • ${court.address}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => CourtFormScreen(court: court)));
                                if (context.mounted) context.read<CourtsBloc>().add(RefreshCourts());
                              } else if (value == 'delete') {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(localizer.deleteCourt),
                                    content: Text(localizer.deleteCourtConfirm),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(localizer.cancel)),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(localizer.delete)),
                                    ],
                                  ),
                                );
                                if ((confirmed ?? false) && context.mounted) {
                                  context.read<CourtsBloc>().add(DeleteCourt(court.courtId));
                                }
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'edit', child: Text(localizer.edit)),
                              PopupMenuItem(value: 'delete', child: Text(localizer.delete)),
                            ],
                          ),
                          onTap: () {
                            context.read<CourtsBloc>().add(SelectCourt(court.courtId));
                            Navigator.push(context, MaterialPageRoute(builder: (_) => CourtDetailScreen(court: court)));
                          },
                        );
                      },
                    ),
                  );
                }
                if (state is CourtDetailLoaded) {
                  final court = state.court;
                  return _buildDetail(court, localizer);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(CourtModel court, AppLocalizations localizer) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(court.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${localizer.address}: ${court.address}'),
          Text('${localizer.governorate}: ${court.governorate}'),
          Text('${localizer.phone}: ${court.phone}'),
          const SizedBox(height: 16),
          Text('${localizer.notes}: ${court.notes}'),
        ],
      ),
    );
  }
}
