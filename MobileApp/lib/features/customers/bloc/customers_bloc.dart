import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/customers_repository.dart';
import 'customers_event.dart';
import 'customers_state.dart';

class CustomersBloc extends Bloc<CustomersEvent, CustomersState> {
  final CustomersRepository customersRepository;

  CustomersBloc({required this.customersRepository}) : super(CustomersInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<SearchCustomers>(_onSearchCustomers);
    on<RefreshCustomers>(_onRefreshCustomers);
    on<LoadCustomerDetail>(_onLoadCustomerDetail);
  }

  Future<void> _onLoadCustomers(LoadCustomers event, Emitter<CustomersState> emit) async {
    emit(CustomersLoading());
    try {
      final customers = await customersRepository.getCustomers();
      emit(CustomersLoaded(customers));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  Future<void> _onSearchCustomers(SearchCustomers event, Emitter<CustomersState> emit) async {
    emit(CustomersLoading());
    try {
      final customers = await customersRepository.searchCustomers(event.query);
      emit(CustomersLoaded(customers));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  Future<void> _onRefreshCustomers(RefreshCustomers event, Emitter<CustomersState> emit) async {
    try {
      final customers = await customersRepository.getCustomers();
      emit(CustomersLoaded(customers));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  Future<void> _onLoadCustomerDetail(LoadCustomerDetail event, Emitter<CustomersState> emit) async {
    emit(CustomersLoading());
    try {
      final customer = await customersRepository.getCustomerById(event.customerId);
      if (customer != null) {
        emit(CustomerDetailLoaded(customer));
      } else {
        emit(CustomersError('Customer not found'));
      }
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }
}
