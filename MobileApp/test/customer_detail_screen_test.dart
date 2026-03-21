import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lawyersys_mobile/core/api/api_client.dart';
import 'package:lawyersys_mobile/core/localization/app_localizations.dart';
import 'package:lawyersys_mobile/core/storage/local_database.dart';
import 'package:lawyersys_mobile/features/cases/models/case.dart';
import 'package:lawyersys_mobile/features/cases/repositories/cases_repository.dart';
import 'package:lawyersys_mobile/features/customers/bloc/customers_bloc.dart';
import 'package:lawyersys_mobile/features/customers/repositories/customers_repository.dart';
import 'package:lawyersys_mobile/features/customers/screens/customer_detail_screen.dart';
import 'package:lawyersys_mobile/features/customers/models/customer.dart';

class FakeCustomersRepository extends CustomersRepository {
  FakeCustomersRepository() : super(ApiClient());

  @override
  Future<Customer?> getCustomerById(String customerId) async {
    return Customer(
      customerId: customerId,
      fullName: 'Fatima Aziz',
      phoneNumber: '055-1234',
      ssn: '1234567890',
      email: 'fatima@example.com',
      address: 'Najd Street, Riyadh',
    );
  }

  @override
  Future<List<Customer>> getCustomers({int page = 1, int pageSize = 50}) async {
    return [
      Customer(
        customerId: 'C1',
        fullName: 'Fatima Aziz',
        phoneNumber: '055-1234',
        ssn: '1234567890',
        email: 'fatima@example.com',
        address: 'Najd Street, Riyadh',
      ),
    ];
  }

  @override
  Future<List<Customer>> searchCustomers(String query) async {
    return getCustomers();
  }
}

class FakeCasesRepository extends CasesRepository {
  FakeCasesRepository() : super(ApiClient(), LocalDatabase.instance);

  @override
  Future<List<CustomerCaseHistoryItem>> getCasesByCustomerId(String customerId, {String? tenantId}) async {
    return [
      CustomerCaseHistoryItem(
        caseId: '1',
        caseName: 'Divorce 2026',
        caseCode: 'DV-100',
        assignedEmployeeName: 'Lawyer Sami',
      ),
      CustomerCaseHistoryItem(
        caseId: '2',
        caseName: 'Property Transfer',
        caseCode: 'PT-200',
        assignedEmployeeName: 'Lawyer Nadia',
      ),
    ];
  }
}

void main() {
  testWidgets('CustomerDetailScreen displays case history items', (WidgetTester tester) async {
    final customersRepository = FakeCustomersRepository();
    final casesRepository = FakeCasesRepository();
    final customersBloc = CustomersBloc(customersRepository: customersRepository);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: RepositoryProvider.value(
          value: casesRepository,
          child: BlocProvider.value(
            value: customersBloc,
            child: const CustomerDetailScreen(customerId: 'C1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Customer Details'), findsOneWidget);
    expect(find.text('Fatima Aziz'), findsOneWidget);
    expect(find.text('Case History'), findsOneWidget);
    expect(find.text('Divorce 2026'), findsOneWidget);
    expect(find.text('Property Transfer'), findsOneWidget);
    expect(find.text('DV-100'), findsOneWidget);
    expect(find.text('PT-200'), findsOneWidget);
    expect(find.textContaining('Assigned to'), findsOneWidget);

    customersBloc.close();
  });

  testWidgets('CustomerDetailScreen includes direct call and message actions', (WidgetTester tester) async {
    final customersRepository = FakeCustomersRepository();
    final casesRepository = FakeCasesRepository();
    final customersBloc = CustomersBloc(customersRepository: customersRepository);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: RepositoryProvider.value(
          value: casesRepository,
          child: BlocProvider.value(
            value: customersBloc,
            child: const CustomerDetailScreen(customerId: 'C1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);

    customersBloc.close();
  });
}
