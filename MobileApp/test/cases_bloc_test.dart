import 'package:flutter_test/flutter_test.dart';
import 'package:lawyersys_mobile/core/api/api_client.dart';
import 'package:lawyersys_mobile/core/storage/local_database.dart';
import 'package:lawyersys_mobile/features/cases/bloc/cases_bloc.dart';
import 'package:lawyersys_mobile/features/cases/bloc/cases_event.dart';
import 'package:lawyersys_mobile/features/cases/bloc/cases_state.dart';
import 'package:lawyersys_mobile/features/cases/models/case.dart';
import 'package:lawyersys_mobile/features/cases/repositories/cases_repository.dart';

class FakeCasesRepository extends CasesRepository {
  final List<CaseModel> _items;

  FakeCasesRepository(this._items) : super(ApiClient(), LocalDatabase.instance);

  @override
  Future<List<CaseModel>> getCases({String? tenantId, int page = 0, int pageSize = 20}) async {
    return _items;
  }

  @override
  Future<void> createCase(CaseModel caseModel) async {
    _items.add(caseModel);
  }

  @override
  Future<void> updateCase(CaseModel caseModel) async {
    final index = _items.indexWhere((c) => c.caseId == caseModel.caseId);
    if (index >= 0) _items[index] = caseModel;
  }

  @override
  Future<void> deleteCase(String caseId) async {
    _items.removeWhere((c) => c.caseId == caseId);
  }

  @override
  Future<List<CaseModel>> searchCases(String query, {String? tenantId}) async {
    return _items.where((c) => c.caseNumber.contains(query) || c.customerFullName.contains(query)).toList();
  }
}

void main() {
  test('Create/update/delete case through CasesBloc', () async {
    final initialCase = CaseModel(
      caseId: '1',
      tenantId: 't1',
      caseNumber: 'C-001',
      invitationType: 'Online',
      caseStatus: 'Open',
      caseType: 'Civil',
      filingDate: DateTime(2025, 1, 1),
      closingDate: null,
      customerId: 'c1',
      customerFullName: 'Jane Doe',
      courtId: 'court1',
      courtName: 'Main Court',
      assignedEmployees: [],
    );

    final repo = FakeCasesRepository([initialCase]);
    final bloc = CasesBloc(casesRepository: repo);

    final states = <CasesState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(LoadCases());
    await Future.delayed(const Duration(milliseconds: 50));

    expect(states.last, isA<CasesLoaded>());

    final newCase = CaseModel(
      caseId: '2',
      tenantId: 't1',
      caseNumber: 'C-002',
      invitationType: 'Online',
      caseStatus: 'Open',
      caseType: 'Civil',
      filingDate: DateTime(2025, 2, 1),
      closingDate: null,
      customerId: 'c2',
      customerFullName: 'John Smith',
      courtId: 'court1',
      courtName: 'Main Court',
      assignedEmployees: [],
    );

    bloc.add(CreateCase(newCase));
    await Future.delayed(const Duration(milliseconds: 50));

    expect(repo.getCases().then((list) => list.length), completion(2));

    final updatedCase = CaseModel(
      caseId: '2',
      tenantId: 't1',
      caseNumber: 'C-002',
      invitationType: 'Online',
      caseStatus: 'Closed',
      caseType: 'Civil',
      filingDate: DateTime(2025, 2, 1),
      closingDate: DateTime(2025, 3, 1),
      customerId: 'c2',
      customerFullName: 'John Smith',
      courtId: 'court1',
      courtName: 'Main Court',
      assignedEmployees: [],
    );

    bloc.add(UpdateCase(updatedCase));
    await Future.delayed(const Duration(milliseconds: 50));

    final updated = await repo.getCases();
    expect(updated.firstWhere((c) => c.caseId == '2').caseStatus, 'Closed');

    bloc.add(DeleteCase('2'));
    await Future.delayed(const Duration(milliseconds: 50));

    final afterDelete = await repo.getCases();
    expect(afterDelete.any((c) => c.caseId == '2'), isFalse);

    await sub.cancel();
    await bloc.close();
  });
}
