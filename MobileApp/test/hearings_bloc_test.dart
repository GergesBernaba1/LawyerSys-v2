import 'package:flutter_test/flutter_test.dart';
import 'package:lawyersys_mobile/core/api/api_client.dart';
import 'package:lawyersys_mobile/core/storage/local_database.dart';
import 'package:lawyersys_mobile/features/hearings/bloc/hearings_bloc.dart';
import 'package:lawyersys_mobile/features/hearings/bloc/hearings_event.dart';
import 'package:lawyersys_mobile/features/hearings/bloc/hearings_state.dart';
import 'package:lawyersys_mobile/features/hearings/models/hearing.dart';
import 'package:lawyersys_mobile/features/hearings/repositories/hearings_repository.dart';

class FakeHearingsRepository extends HearingsRepository {
  final List<Hearing> _items;

  FakeHearingsRepository(this._items) : super(ApiClient(), LocalDatabase.instance);

  @override
  Future<List<Hearing>> getHearings({String? tenantId, int page = 1, int pageSize = 50, DateTime? startDate, DateTime? endDate}) async {
    return _items;
  }

  @override
  Future<Hearing?> getHearingById(String hearingId) async {
    return _items.firstWhere((h) => h.hearingId == hearingId, orElse: () => throw StateError('Not found'));
  }

  @override
  Future<void> createHearing(Hearing hearing) async {
    _items.add(hearing);
  }

  @override
  Future<void> updateHearing(Hearing hearing) async {
    final index = _items.indexWhere((h) => h.hearingId == hearing.hearingId);
    if (index >= 0) _items[index] = hearing;
  }

  @override
  Future<void> deleteHearing(String hearingId) async {
    _items.removeWhere((h) => h.hearingId == hearingId);
  }

  @override
  Future<List<Hearing>> searchHearings(String query, {String? tenantId}) async {
    return _items.where((h) => h.caseNumber.contains(query) || h.judgeName.contains(query)).toList();
  }
}

void main() {
  test('Create/update/delete hearing through HearingsBloc', () async {
    final now = DateTime.now();
    final hearing1 = Hearing(
      hearingId: 'H1',
      tenantId: 'T1',
      hearingDate: now,
      caseId: 'C1',
      caseNumber: 'CASE-001',
      judgeName: 'Judge A',
      courtId: 'CR1',
      courtName: 'Court A',
      courtLocation: 'Building A',
    );

    final repo = FakeHearingsRepository([hearing1]);
    final bloc = HearingsBloc(hearingsRepository: repo);
    final states = <HearingsState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(LoadHearings());
    await Future.delayed(const Duration(milliseconds: 50));
    expect(states.last, isA<HearingsLoaded>());

    final newHearing = Hearing(
      hearingId: 'H2',
      tenantId: 'T1',
      hearingDate: now.add(const Duration(days: 1)),
      caseId: 'C2',
      caseNumber: 'CASE-002',
      judgeName: 'Judge B',
      courtId: 'CR2',
      courtName: 'Court B',
      courtLocation: 'Building B',
    );

    bloc.add(CreateHearing(newHearing));
    await Future.delayed(const Duration(milliseconds: 50));
    expect(repo.getHearings().then((list) => list.length), completion(2));
    expect(states.last, isA<HearingOperationSuccess>());

    final updatedHearing = Hearing(
      hearingId: 'H2',
      tenantId: 'T1',
      hearingDate: now.add(const Duration(days: 1)),
      caseId: 'C2',
      caseNumber: 'CASE-002',
      judgeName: 'Judge B Updated',
      courtId: 'CR2',
      courtName: 'Court B',
      courtLocation: 'Building B',
    );

    bloc.add(UpdateHearing(updatedHearing));
    await Future.delayed(const Duration(milliseconds: 50));
    expect((await repo.getHearings()).firstWhere((h) => h.hearingId == 'H2').judgeName, 'Judge B Updated');

    bloc.add(DeleteHearing('H2'));
    await Future.delayed(const Duration(milliseconds: 50));
    expect(repo.getHearings().then((list) => list.any((h) => h.hearingId == 'H2')), completion(isFalse));

    await sub.cancel();
    await bloc.close();
  });
}
