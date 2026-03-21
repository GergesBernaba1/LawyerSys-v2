import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lawyersys_mobile/core/api/api_client.dart';
import 'package:lawyersys_mobile/features/hearings/bloc/hearings_bloc.dart';
import 'package:lawyersys_mobile/features/hearings/bloc/hearings_event.dart';
import 'package:lawyersys_mobile/features/hearings/bloc/hearings_state.dart';
import 'package:lawyersys_mobile/features/hearings/models/hearing.dart';
import 'package:lawyersys_mobile/features/hearings/repositories/hearings_repository.dart';
import 'package:lawyersys_mobile/features/hearings/screens/hearings_list_screen.dart';
import 'package:lawyersys_mobile/core/localization/app_localizations.dart';

class FakeHearingsRepository extends HearingsRepository {
  FakeHearingsRepository() : super(ApiClient());

  @override
  Future<List<Hearing>> getHearings({int page = 1, int pageSize = 50}) async {
    final now = DateTime.now();
    return [
      Hearing(
        hearingId: 'H1',
        hearingDate: DateTime(now.year, now.month, now.day, 10, 30),
        caseNumber: 'CASE-001',
        judgeName: 'Judge Smith',
        courtLocation: 'Court A',
        notes: 'Initial hearing',
      ),
      Hearing(
        hearingId: 'H2',
        hearingDate: DateTime(now.year, now.month, now.day + 1, 14, 0),
        caseNumber: 'CASE-002',
        judgeName: 'Judge Ali',
        courtLocation: 'Court B',
        notes: 'Follow-up',
      ),
    ];
  }

  @override
  Future<List<Hearing>> searchHearings(String query) async {
    final all = await getHearings();
    return all.where((hearing) => hearing.caseNumber.contains(query)).toList();
  }
}

void main() {
  testWidgets('HearingsListScreen renders list and calendar view with markers', (WidgetTester tester) async {
    final repository = FakeHearingsRepository();
    final hearingsBloc = HearingsBloc(hearingsRepository: repository);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: BlocProvider.value(
          value: hearingsBloc,
          child: const HearingsListScreen(),
        ),
      ),
    );

    // Initial load should dispatch event and update state
    await tester.pumpAndSettle();

    expect(find.text('Hearings'), findsOneWidget);
    expect(find.text('CASE-001'), findsOneWidget);
    expect(find.text('CASE-002'), findsOneWidget);

    // Toggle to calendar view
    final toggleButton = find.widgetWithText(TextButton, 'Calendar View');
    expect(toggleButton, findsOneWidget);
    await tester.tap(toggleButton);
    await tester.pumpAndSettle();

    // Calendar widget should now be present
    expect(find.byType(TableCalendar<Hearing>), findsOneWidget);

    // Selected day event should show list entry for the first hearing
    expect(find.text('CASE-001'), findsOneWidget);

    hearingsBloc.close();
  });
}
