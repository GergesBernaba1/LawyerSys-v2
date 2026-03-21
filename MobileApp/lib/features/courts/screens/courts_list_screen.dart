import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/courts_bloc.dart';
import '../bloc/courts_event.dart';
import '../bloc/courts_state.dart';
import '../models/court.dart';
import 'court_detail_screen.dart';
import 'court_form_screen.dart';

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
    final localizer = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localizer.courts ?? 'Courts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CourtFormScreen()));
          context.read<CourtsBloc>().add(RefreshCourts());
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
                hintText: localizer.search ?? 'Search',
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
                    return Center(child: Text(localizer.noData ?? 'No courts found'));
                  }
                  return ListView.builder(
                    itemCount: courts.length,
                    itemBuilder: (context, index) {
                      final court = courts[index];
                      return ListTile(
                        title: Text(court.name),
                        subtitle: Text('${court.governorate} • ${court.address}'),
                        onTap: () {
                          context.read<CourtsBloc>().add(SelectCourt(court.courtId));
                          Navigator.push(context, MaterialPageRoute(builder: (_) => CourtDetailScreen(court: court)));
                        },
                      );
                    },
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
          Text('${localizer.governorate ?? 'Governorate'}: ${court.governorate}'),
          Text('${localizer.phone ?? 'Phone'}: ${court.phone}'),
          const SizedBox(height: 16),
          Text('${localizer.notes ?? 'Notes'}: ${court.notes}'),
        ],
      ),
    );
  }
}
