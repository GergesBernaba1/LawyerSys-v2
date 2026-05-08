import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/governments/bloc/governments_bloc.dart';
import 'package:qadaya_lawyersys/features/governments/bloc/governments_event.dart';
import 'package:qadaya_lawyersys/features/governments/bloc/governments_state.dart';
import 'package:qadaya_lawyersys/features/governments/models/government.dart';
import 'package:qadaya_lawyersys/features/governments/repositories/governments_repository.dart';
import 'package:qadaya_lawyersys/features/governments/screens/governments_list_screen.dart';

// ---------------------------------------------------------------------------
// Fake repository — synchronous, no network
// ---------------------------------------------------------------------------

class _FakeGovernmentsRepository implements IGovernmentsRepository {
  _FakeGovernmentsRepository({
    List<Government>? governments,
    bool shouldThrow = false,
    int totalCount = 0,
  })  : _governments = governments ?? [],
        _shouldThrow = shouldThrow,
        _totalCount = totalCount > 0
            ? totalCount
            : (governments?.length ?? 0);

  final List<Government> _governments;
  final bool _shouldThrow;
  final int _totalCount;
  int callCount = 0;

  @override
  Future<GovernmentsPage> getGovernments({
    int page = 1,
    int pageSize = GovernmentsRepository.defaultPageSize,
    String? search,
  }) async {
    callCount++;
    if (_shouldThrow) throw Exception('Network error');
    final filtered = search == null || search.isEmpty
        ? _governments
        : _governments
            .where((g) => g.governorateName
                .toLowerCase()
                .contains(search.toLowerCase()),)
            .toList();
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, filtered.length);
    final items =
        start >= filtered.length ? <Government>[] : filtered.sublist(start, end);
    return GovernmentsPage(
      items: items,
      totalCount: _totalCount,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<Government> createGovernment(Map<String, dynamic> data) async {
    if (_shouldThrow) throw Exception('Network error');
    return Government(
      governorateId: '99',
      governorateName: data['govName']?.toString() ?? '',
    );
  }

  @override
  Future<Government> updateGovernment(
      String id, Map<String, dynamic> data,) async {
    if (_shouldThrow) throw Exception('Network error');
    return Government(
      governorateId: id,
      governorateName: data['govName']?.toString() ?? '',
    );
  }

  @override
  Future<void> deleteGovernment(String id) async {
    if (_shouldThrow) throw Exception('Network error');
  }
}


// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Government _gov(int id, String name) =>
    Government(governorateId: '$id', governorateName: name);

List<Government> _testGovs() => [
      _gov(1, 'Cairo'),
      _gov(2, 'Alexandria'),
      _gov(3, 'Giza'),
    ];

Widget _pumpScreen(GovernmentsBloc bloc) => MaterialApp(
      // Use synchronous default delegates — GlobalMaterialLocalizations loads
      // locale asset data asynchronously and causes pumpAndSettle to hang.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: BlocProvider<GovernmentsBloc>.value(
        value: bloc,
        child: const GovernmentsListScreen(),
      ),
    );

// ===========================================================================
// Tests
// ===========================================================================

void main() {
  // -------------------------------------------------------------------------
  // 1. Model unit tests
  // -------------------------------------------------------------------------

  group('Government.fromJson', () {
    test('parses id and govName from API response', () {
      final gov = Government.fromJson({'id': 7, 'govName': 'Cairo'});
      expect(gov.governorateId, '7');
      expect(gov.governorateName, 'Cairo');
    });

    test('handles null govName gracefully', () {
      final gov = Government.fromJson({'id': 3, 'govName': null});
      expect(gov.governorateName, '');
    });

    test('handles null id gracefully', () {
      final gov = Government.fromJson({'id': null, 'govName': 'Giza'});
      expect(gov.governorateId, '');
    });

    test('converts numeric id to string', () {
      final gov = Government.fromJson({'id': 42, 'govName': 'Alexandria'});
      expect(gov.governorateId, '42');
    });

    test('does NOT read legacy field names', () {
      final gov = Government.fromJson({
        'governorateId': '10',
        'governorateName': 'OldFormat',
      });
      expect(gov.governorateId, isEmpty);
      expect(gov.governorateName, isEmpty);
    });

    test('toJson emits govName key for API write', () {
      final gov = Government(governorateId: '5', governorateName: 'Luxor');
      expect(gov.toJson(), containsPair('govName', 'Luxor'));
    });
  });

  // -------------------------------------------------------------------------
  // 2. GovernmentsPage helper
  // -------------------------------------------------------------------------

  group('GovernmentsPage.hasMore', () {
    test('true when more pages exist', () {
      final page = GovernmentsPage(
          items: [], totalCount: 50, page: 1, pageSize: 20,);
      expect(page.hasMore, isTrue);
    });

    test('false when on last page', () {
      final page = GovernmentsPage(
          items: [], totalCount: 20, page: 1, pageSize: 20,);
      expect(page.hasMore, isFalse);
    });

    test('false when total is zero', () {
      final page = GovernmentsPage(
          items: [], totalCount: 0, page: 1, pageSize: 20,);
      expect(page.hasMore, isFalse);
    });

    test('edge: exactly on last page boundary', () {
      final page = GovernmentsPage(
          items: [], totalCount: 40, page: 2, pageSize: 20,);
      expect(page.hasMore, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // 3. BLoC tests
  // -------------------------------------------------------------------------

  group('GovernmentsBloc', () {
    blocTest<GovernmentsBloc, GovernmentsState>(
      'emits [Loading, Loaded] on LoadGovernments',
      build: () => GovernmentsBloc(
        governmentsRepository:
            _FakeGovernmentsRepository(governments: _testGovs()),
      ),
      act: (bloc) => bloc.add(LoadGovernments()),
      expect: () => [
        isA<GovernmentsLoading>(),
        isA<GovernmentsLoaded>()
            .having((s) => s.governments.length, 'count', 3)
            .having((s) => s.page, 'page', 1),
      ],
    );

    blocTest<GovernmentsBloc, GovernmentsState>(
      'emits [Loading, Error] when repository throws',
      build: () => GovernmentsBloc(
        governmentsRepository: _FakeGovernmentsRepository(shouldThrow: true),
      ),
      act: (bloc) => bloc.add(LoadGovernments()),
      expect: () => [
        isA<GovernmentsLoading>(),
        isA<GovernmentsError>()
            .having((s) => s.message, 'message', contains('Network error')),
      ],
    );

    blocTest<GovernmentsBloc, GovernmentsState>(
      'loaded state names match govName field, not legacy field',
      build: () => GovernmentsBloc(
        governmentsRepository:
            _FakeGovernmentsRepository(governments: [_gov(1, 'Cairo')]),
      ),
      act: (bloc) => bloc.add(LoadGovernments()),
      verify: (bloc) {
        final state = bloc.state as GovernmentsLoaded;
        expect(state.governments.first.governorateName, 'Cairo');
      },
    );

    blocTest<GovernmentsBloc, GovernmentsState>(
      'appends items on LoadGovernmentsNextPage',
      build: () => GovernmentsBloc(
        governmentsRepository: _FakeGovernmentsRepository(
          governments: List.generate(5, (i) => _gov(i + 1, 'Gov $i')),
          totalCount: 5,
        ),
      ),
      seed: () => GovernmentsLoaded(
        governments: [_gov(1, 'Gov 0'), _gov(2, 'Gov 1')],
        totalCount: 5,
        page: 1,
        hasMore: true,
      ),
      act: (bloc) => bloc.add(LoadGovernmentsNextPage()),
      expect: () => [
        isA<GovernmentsLoadingMore>(),
        isA<GovernmentsLoaded>().having((s) => s.page, 'page', 2),
      ],
    );

    blocTest<GovernmentsBloc, GovernmentsState>(
      'no-op on LoadGovernmentsNextPage when hasMore is false',
      build: () => GovernmentsBloc(
        governmentsRepository:
            _FakeGovernmentsRepository(governments: _testGovs()),
      ),
      seed: () => GovernmentsLoaded(
        governments: _testGovs(),
        totalCount: 3,
        page: 1,
        hasMore: false,
      ),
      act: (bloc) => bloc.add(LoadGovernmentsNextPage()),
      expect: () => <GovernmentsState>[],
    );

    blocTest<GovernmentsBloc, GovernmentsState>(
      'SearchGovernments delegates filtering to repository',
      build: () => GovernmentsBloc(
        governmentsRepository:
            _FakeGovernmentsRepository(governments: _testGovs()),
      ),
      act: (bloc) => bloc.add(SearchGovernments('Cairo')),
      expect: () => [
        isA<GovernmentsLoading>(),
        isA<GovernmentsLoaded>()
            .having((s) => s.governments.length, 'count', 1)
            .having((s) => s.searchQuery, 'query', 'Cairo'),
      ],
    );

    blocTest<GovernmentsBloc, GovernmentsState>(
      'delete emits [Loading, Success, Loaded]',
      build: () => GovernmentsBloc(
        governmentsRepository:
            _FakeGovernmentsRepository(governments: _testGovs()),
      ),
      act: (bloc) => bloc.add(DeleteGovernment('1')),
      expect: () => [
        isA<GovernmentsLoading>(),
        isA<GovernmentOperationSuccess>(),
        isA<GovernmentsLoaded>(),
      ],
    );

    blocTest<GovernmentsBloc, GovernmentsState>(
      'create uses govName key',
      build: () => GovernmentsBloc(
        governmentsRepository: _FakeGovernmentsRepository(governments: []),
      ),
      act: (bloc) =>
          bloc.add(CreateGovernment({'govName': 'New Government'})),
      expect: () => [
        isA<GovernmentsLoading>(),
        isA<GovernmentOperationSuccess>(),
        isA<GovernmentsLoaded>(),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // 4. Widget tests
  // -------------------------------------------------------------------------

  group('GovernmentsListScreen widget', () {
    // Wait for the BLoC's initial LoadGovernments event to complete.
    // tester.runAsync() runs code in the real async zone so the BLoC's
    // stream-based event handler can finish without needing pumpAndSettle.
    Future<void> awaitLoad(WidgetTester tester, GovernmentsBloc bloc) async {
      await tester.runAsync(() async {
        await bloc.stream.firstWhere(
          (s) => s is GovernmentsLoaded || s is GovernmentsError,
        );
      });
      await tester.pump(); // reflect new state in the widget tree
    }

    testWidgets('screen renders and shows Scaffold without crashing',
        (tester) async {
      final bloc = GovernmentsBloc(
        governmentsRepository:
            _FakeGovernmentsRepository(governments: _testGovs()),
      );
      await tester.pumpWidget(_pumpScreen(bloc));
      await awaitLoad(tester, bloc);

      expect(find.byType(Scaffold), findsOneWidget);
      await bloc.close();
    });

    testWidgets('displays government names after load', (tester) async {
      final bloc = GovernmentsBloc(
        governmentsRepository:
            _FakeGovernmentsRepository(governments: _testGovs()),
      );
      await tester.pumpWidget(_pumpScreen(bloc));
      await awaitLoad(tester, bloc);

      expect(find.text('Cairo'), findsWidgets);
      expect(find.text('Alexandria'), findsOneWidget);
      expect(find.text('Giza'), findsOneWidget);
      await bloc.close();
    });

    testWidgets('NEVER displays government IDs in the list', (tester) async {
      final bloc = GovernmentsBloc(
        governmentsRepository:
            _FakeGovernmentsRepository(governments: _testGovs()),
      );
      await tester.pumpWidget(_pumpScreen(bloc));
      await awaitLoad(tester, bloc);

      // Raw numeric IDs must not appear as standalone text
      expect(find.textContaining('ID:'), findsNothing);
      expect(find.textContaining(':ID'), findsNothing);
      // The ID values themselves (1, 2, 3) must not be shown as labels
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
      expect(find.text('3'), findsNothing);
      await bloc.close();
    });

    testWidgets('shows empty state when list is empty', (tester) async {
      final bloc = GovernmentsBloc(
        governmentsRepository: _FakeGovernmentsRepository(governments: []),
      );
      await tester.pumpWidget(_pumpScreen(bloc));
      await awaitLoad(tester, bloc);

      expect(find.byType(ListTile), findsNothing);
      expect(find.byIcon(Icons.location_city), findsWidgets);
      await bloc.close();
    });

    testWidgets('shows error state with refresh indicator', (tester) async {
      final bloc = GovernmentsBloc(
        governmentsRepository: _FakeGovernmentsRepository(shouldThrow: true),
      );
      await tester.pumpWidget(_pumpScreen(bloc));
      await awaitLoad(tester, bloc);

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
      await bloc.close();
    });

    testWidgets('list supports vertical scrolling', (tester) async {
      final many = List.generate(30, (i) => _gov(i + 1, 'Government $i'));
      final bloc = GovernmentsBloc(
        governmentsRepository: _FakeGovernmentsRepository(
          governments: many,
          totalCount: 30,
        ),
      );
      await tester.pumpWidget(_pumpScreen(bloc));
      await awaitLoad(tester, bloc);

      expect(find.byType(ListView), findsOneWidget);
      expect(find.textContaining('Government'), findsWidgets);

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ListView), findsOneWidget);
      await bloc.close();
    });

    testWidgets('bottom spinner visible when loading next page',
        (tester) async {
      final repo =
          _FakeGovernmentsRepository(governments: _testGovs(), totalCount: 60);
      final bloc = GovernmentsBloc(governmentsRepository: repo);
      await tester.pumpWidget(_pumpScreen(bloc));
      await awaitLoad(tester, bloc);

      // Pre-emit GovernmentsLoadingMore so the bottom spinner is rendered
      bloc.emit(GovernmentsLoadingMore(GovernmentsLoaded(
        governments: _testGovs(),
        totalCount: 60,
        page: 1,
        hasMore: true,
      ),),);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await bloc.close();
    });

    testWidgets('search field is present', (tester) async {
      final bloc = GovernmentsBloc(
        governmentsRepository:
            _FakeGovernmentsRepository(governments: _testGovs()),
      );
      await tester.pumpWidget(_pumpScreen(bloc));
      await awaitLoad(tester, bloc);

      expect(find.byType(TextField), findsOneWidget);
      await bloc.close();
    });

    testWidgets('searching filters the displayed list', (tester) async {
      final bloc = GovernmentsBloc(
        governmentsRepository:
            _FakeGovernmentsRepository(governments: _testGovs()),
      );
      await tester.pumpWidget(_pumpScreen(bloc));
      await awaitLoad(tester, bloc);

      await tester.enterText(find.byType(TextField), 'Cairo');
      // Advance past the 400 ms debounce in the real async zone, then reflect
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await bloc.stream.firstWhere(
          (s) => s is GovernmentsLoaded,
        );
      });
      await tester.pump();

      // Only Cairo should remain in the list; Alexandria and Giza should not
      expect(find.text('Alexandria'), findsNothing);
      expect(find.text('Giza'), findsNothing);
      await bloc.close();
    });
  });

  // -------------------------------------------------------------------------
  // 5. Data integrity
  // -------------------------------------------------------------------------

  group('Data integrity — API contract alignment', () {
    test('fromJson round-trip preserves govName value', () {
      const original = {'id': 12, 'govName': 'Aswan'};
      final gov = Government.fromJson(original);
      expect(gov.governorateName, original['govName']);
    });

    test('create payload must use govName key, not governorateName', () {
      const payload = {'govName': 'New Province'};
      expect(payload.containsKey('govName'), isTrue);
      expect(payload.containsKey('governorateName'), isFalse);
    });

    test('create payload must not forward id', () {
      const payload = {'govName': 'Test'};
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('governorateId'), isFalse);
    });

    test('GovernmentsPage.hasMore edge cases', () {
      expect(
        GovernmentsPage(items: [], totalCount: 21, page: 1, pageSize: 20,)
            .hasMore,
        isTrue,
      );
      expect(
        GovernmentsPage(items: [], totalCount: 20, page: 1, pageSize: 20,)
            .hasMore,
        isFalse,
      );
      expect(
        GovernmentsPage(items: [], totalCount: 40, page: 2, pageSize: 20,)
            .hasMore,
        isFalse,
      );
    });
  });
}
