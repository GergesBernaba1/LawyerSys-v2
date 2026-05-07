import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/core/storage/local_database.dart';
import 'package:qadaya_lawyersys/features/hearings/bloc/hearings_bloc.dart';
import 'package:qadaya_lawyersys/features/hearings/models/hearing.dart';
import 'package:qadaya_lawyersys/features/hearings/repositories/hearings_repository.dart';
import 'package:qadaya_lawyersys/features/hearings/screens/hearings_list_screen.dart';
import 'package:table_calendar/table_calendar.dart';

class FakeHearingsRepository extends HearingsRepository {
  FakeHearingsRepository() : super(ApiClient(), LocalDatabase.instance);

  @override
  Future<List<Hearing>> getHearings({String? tenantId, int page = 1, int pageSize = 50, DateTime? startDate, DateTime? endDate}) async {
    final now = DateTime.now();
    return [
      Hearing(
        hearingId: 'H1',
        tenantId: '',
        hearingDate: DateTime(now.year, now.month, now.day, 10, 30),
        caseId: 'C1',
        caseNumber: 'CASE-001',
        judgeName: 'Judge Smith',
        courtId: 'CT1',
        courtName: 'Court A',
        courtLocation: 'Court A',
        notes: 'Initial hearing',
      ),
      Hearing(
        hearingId: 'H2',
        tenantId: '',
        hearingDate: DateTime(now.year, now.month, now.day + 1, 14),
        caseId: 'C2',
        caseNumber: 'CASE-002',
        judgeName: 'Judge Ali',
        courtId: 'CT2',
        courtName: 'Court B',
        courtLocation: 'Court B',
        notes: 'Follow-up',
      ),
    ];
  }

  @override
  Future<List<Hearing>> searchHearings(String query, {String? tenantId}) async {
    final all = await getHearings();
    return all.where((hearing) => hearing.caseNumber.contains(query)).toList();
  }
}

void main() {
  testWidgets('HearingsListScreen renders list and calendar view with markers', (tester) async {
    // Use a taller viewport so the calendar + events list both fit.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    expect(find.text('Case Number: CASE-001'), findsOneWidget);
    expect(find.text('Case Number: CASE-002'), findsOneWidget);

    // Toggle to calendar view
    final toggleButton = find.widgetWithText(TextButton, 'Calendar View');
    expect(toggleButton, findsOneWidget);
    await tester.tap(toggleButton);
    await tester.pumpAndSettle();

    // Calendar widget should now be present
    expect(find.byType(TableCalendar<Hearing>), findsOneWidget);

    // Selected day event should show list entry for the first hearing
    expect(find.textContaining('CASE-001'), findsOneWidget);

    hearingsBloc.close();
  });
}
