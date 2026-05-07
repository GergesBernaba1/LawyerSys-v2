import 'package:flutter_test/flutter_test.dart';
import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/storage/local_database.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/cases_bloc.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/cases_event.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/cases_state.dart';
import 'package:qadaya_lawyersys/features/cases/models/case.dart';
import 'package:qadaya_lawyersys/features/cases/repositories/cases_repository.dart';

class FakeCasesRepository extends CasesRepository {

  FakeCasesRepository(this._items) : super(ApiClient(), LocalDatabase.instance);
  final List<CaseModel> _items;

  @override
  Future<List<CaseModel>> getCases(
      {String? tenantId, int page = 1, int pageSize = 20,}) async {
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
    return _items
        .where((c) =>
            c.caseNumber.contains(query) || c.invitionType.contains(query),)
        .toList();
  }
}

void main() {
  test('Create/update/delete case through CasesBloc', () async {
    final initialCase = CaseModel(
      id: 1,
      code: 1,
      tenantId: 't1',
      invitionsStatment: 'Initial statement',
      invitionType: 'Civil',
      invitionDate: DateTime(2025),
      totalAmount: 1000,
      notes: '',
      status: 0,
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
      id: 2,
      code: 2,
      tenantId: 't1',
      invitionsStatment: 'Second statement',
      invitionType: 'Civil',
      invitionDate: DateTime(2025, 2),
      totalAmount: 1200,
      notes: '',
      status: 0,
      assignedEmployees: [],
    );

    bloc.add(CreateCase(newCase));
    await Future.delayed(const Duration(milliseconds: 50));

    expect(repo.getCases().then((list) => list.length), completion(2));

    final updatedCase = CaseModel(
      id: 2,
      code: 2,
      tenantId: 't1',
      invitionsStatment: 'Second statement',
      invitionType: 'Civil',
      invitionDate: DateTime(2025, 2),
      totalAmount: 1200,
      notes: 'closed',
      status: 3,
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
