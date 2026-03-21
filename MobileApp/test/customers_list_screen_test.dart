import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lawyersys_mobile/core/api/api_client.dart';
import 'package:lawyersys_mobile/core/localization/app_localizations.dart';
import 'package:lawyersys_mobile/features/customers/bloc/customers_bloc.dart';
import 'package:lawyersys_mobile/features/customers/repositories/customers_repository.dart';
import 'package:lawyersys_mobile/features/customers/screens/customers_list_screen.dart';
import 'package:lawyersys_mobile/features/customers/models/customer.dart';

class FakeCustomersRepository extends CustomersRepository {
  FakeCustomersRepository() : super(ApiClient());

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
      )
    ];
  }

  @override
  Future<List<Customer>> searchCustomers(String query) async {
    return getCustomers();
  }
}

void main() {
  testWidgets('CustomersListScreen supports direct phone and message actions', (WidgetTester tester) async {
    final customersRepository = FakeCustomersRepository();
    final customersBloc = CustomersBloc(customersRepository: customersRepository);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: BlocProvider.value(
          value: customersBloc,
          child: const CustomersListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Customers'), findsOneWidget);
    expect(find.text('Fatima Aziz'), findsOneWidget);

    final menuIcon = find.byIcon(Icons.more_vert);
    expect(menuIcon, findsOneWidget);
    await tester.tap(menuIcon);
    await tester.pumpAndSettle();

    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);

    customersBloc.close();
  });
}
