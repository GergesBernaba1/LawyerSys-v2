import 'package:flutter_test/flutter_test.dart';
import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/features/customers/bloc/customers_bloc.dart';
import 'package:qadaya_lawyersys/features/customers/bloc/customers_event.dart';
import 'package:qadaya_lawyersys/features/customers/bloc/customers_state.dart';
import 'package:qadaya_lawyersys/features/customers/models/customer.dart';
import 'package:qadaya_lawyersys/features/customers/repositories/customers_repository.dart';

class FakeCustomersRepository extends CustomersRepository {

  FakeCustomersRepository(this._items) : super(ApiClient());
  final List<Customer> _items;
  String? lastSearchQuery;
  bool createCalled = false;
  String? deletedId;

  @override
  Future<List<Customer>> getCustomers({int page = 1, int pageSize = 50}) async {
    return List.of(_items);
  }

  @override
  Future<List<Customer>> searchCustomers(String query) async {
    lastSearchQuery = query;
    return _items
        .where((c) =>
            c.fullName.toLowerCase().contains(query.toLowerCase()) ||
            (c.phoneNumber ?? '').contains(query),)
        .toList();
  }

  @override
  Future<Customer> createCustomer(Map<String, dynamic> data) async {
    createCalled = true;
    final customer = Customer(
      customerId: data['customerId']?.toString() ?? 'new-id',
      fullName: data['fullName']?.toString() ?? '',
      phoneNumber: data['phoneNumber']?.toString(),
    );
    _items.add(customer);
    return customer;
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    deletedId = customerId;
    _items.removeWhere((c) => c.customerId == customerId);
  }

  @override
  Future<Customer?> getCustomerById(String customerId) async {
    try {
      return _items.firstWhere((c) => c.customerId == customerId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Customer> updateCustomer(
      String customerId, Map<String, dynamic> data,) async {
    final index = _items.indexWhere((c) => c.customerId == customerId);
    final updated = Customer(
      customerId: customerId,
      fullName: data['fullName']?.toString() ?? _items[index].fullName,
    );
    if (index >= 0) _items[index] = updated;
    return updated;
  }
}

void main() {
  late FakeCustomersRepository repo;
  late CustomersBloc bloc;

  final customer1 = Customer(
    customerId: 'c1',
    fullName: 'Alice Smith',
    phoneNumber: '555-0001',
  );
  final customer2 = Customer(
    customerId: 'c2',
    fullName: 'Bob Jones',
    phoneNumber: '555-0002',
  );

  setUp(() {
    repo = FakeCustomersRepository([customer1, customer2]);
    bloc = CustomersBloc(customersRepository: repo);
  });

  tearDown(() async {
    await bloc.close();
  });

  group('CustomersBloc', () {
    test('LoadCustomers emits CustomersLoading then CustomersLoaded', () async {
      bloc.add(LoadCustomers());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CustomersLoading>(),
          isA<CustomersLoaded>(),
        ]),
      );

      final states = <CustomersState>[];
      final freshRepo = FakeCustomersRepository([customer1, customer2]);
      final freshBloc = CustomersBloc(customersRepository: freshRepo);
      final sub = freshBloc.stream.listen(states.add);

      freshBloc.add(LoadCustomers());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.last, isA<CustomersLoaded>());
      final loaded = states.last as CustomersLoaded;
      expect(loaded.customers.length, 2);

      await sub.cancel();
      await freshBloc.close();
    });

    test('SearchCustomers emits CustomersLoading then CustomersLoaded with filtered results',
        () async {
      final states = <CustomersState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(SearchCustomers('Alice'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, greaterThanOrEqualTo(2));
      expect(states[0], isA<CustomersLoading>());
      expect(states[1], isA<CustomersLoaded>());

      final loaded = states[1] as CustomersLoaded;
      expect(loaded.customers.length, 1);
      expect(loaded.customers.first.fullName, 'Alice Smith');
      expect(repo.lastSearchQuery, 'Alice');

      await sub.cancel();
    });

    test('CreateCustomer emits CustomerOperationSuccess then CustomersLoaded',
        () async {
      final states = <CustomersState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(CreateCustomer({'customerId': 'c3', 'fullName': 'Carol White'}));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states, containsAllInOrder([
        isA<CustomersLoading>(),
        isA<CustomerOperationSuccess>(),
        isA<CustomersLoaded>(),
      ]),);

      expect(repo.createCalled, isTrue);
      // after create the repo now has 3 items
      expect(await repo.getCustomers(), hasLength(3));

      await sub.cancel();
    });

    test('DeleteCustomer emits CustomerOperationSuccess then CustomersLoaded',
        () async {
      final states = <CustomersState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(DeleteCustomer('c1'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states, containsAllInOrder([
        isA<CustomersLoading>(),
        isA<CustomerOperationSuccess>(),
        isA<CustomersLoaded>(),
      ]),);

      expect(repo.deletedId, 'c1');
      expect(await repo.getCustomers(), hasLength(1));

      final loaded = states.last as CustomersLoaded;
      expect(loaded.customers.any((c) => c.customerId == 'c1'), isFalse);

      await sub.cancel();
    });
  });
}
