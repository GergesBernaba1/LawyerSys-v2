import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/customers_repository.dart';
import 'customers_event.dart';
import 'customers_state.dart';

class CustomersBloc extends Bloc<CustomersEvent, CustomersState> {
  final CustomersRepository customersRepository;
  final List<dynamic> _customers = [];
  static const int _pageSize = 20;

  CustomersBloc({required this.customersRepository}) : super(CustomersInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<LoadMoreCustomers>(_onLoadMoreCustomers);
    on<SearchCustomers>(_onSearchCustomers);
    on<RefreshCustomers>(_onRefreshCustomers);
    on<LoadCustomerDetail>(_onLoadCustomerDetail);
    on<CreateCustomer>(_onCreateCustomer);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
    on<LoadCaseNotificationPreference>(_onLoadCaseNotificationPreference);
    on<UpdateCaseNotificationPreference>(_onUpdateCaseNotificationPreference);
    on<SubmitPaymentProof>(_onSubmitPaymentProof);
    on<LoadRequestedDocuments>(_onLoadRequestedDocuments);
    on<SubmitRequestedDocument>(_onSubmitRequestedDocument);
  }

  Future<void> _onLoadCustomers(LoadCustomers event, Emitter<CustomersState> emit) async {
    emit(CustomersLoading());
    try {
      final customers = await customersRepository.getCustomers(page: 1, pageSize: _pageSize);
      _customers.clear();
      _customers.addAll(customers);
      emit(CustomersLoaded(
        customers,
        currentPage: 1,
        hasMore: customers.length >= _pageSize,
      ));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  Future<void> _onLoadMoreCustomers(
      LoadMoreCustomers event, Emitter<CustomersState> emit) async {
    final currentState = state;
    if (currentState is! CustomersLoaded || 
        currentState.isLoadingMore || 
        !currentState.hasMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));
    
    try {
      final nextPage = currentState.currentPage + 1;
      final newCustomers = await customersRepository.getCustomers(
        page: nextPage, 
        pageSize: _pageSize,
      );
      
      _customers.addAll(newCustomers);
      
      emit(CustomersLoaded(
        List.from(_customers),
        currentPage: nextPage,
        hasMore: newCustomers.length >= _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
      emit(CustomersError(e.toString()));
    }
  }

  Future<void> _onSearchCustomers(SearchCustomers event, Emitter<CustomersState> emit) async {
    emit(CustomersLoading());
    try {
      final customers = await customersRepository.searchCustomers(event.query);
      emit(CustomersLoaded(
        customers,
        currentPage: 1,
        hasMore: false, // Search doesn't paginate
      ));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  Future<void> _onRefreshCustomers(RefreshCustomers event, Emitter<CustomersState> emit) async {
    try {
      final customers = await customersRepository.getCustomers(page: 1, pageSize: _pageSize);
      _customers.clear();
      _customers.addAll(customers);
      emit(CustomersLoaded(
        customers,
        currentPage: 1,
        hasMore: customers.length >= _pageSize,
      ));
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

  Future<void> _onCreateCustomer(CreateCustomer event, Emitter<CustomersState> emit) async {
    emit(CustomersLoading());
    try {
      await customersRepository.createCustomer(event.data);
      emit(CustomerOperationSuccess('Customer created'));
      final customers = await customersRepository.getCustomers(page: 1, pageSize: _pageSize);
      _customers.clear();
      _customers.addAll(customers);
      emit(CustomersLoaded(
        customers,
        currentPage: 1,
        hasMore: customers.length >= _pageSize,
      ));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  Future<void> _onUpdateCustomer(UpdateCustomer event, Emitter<CustomersState> emit) async {
    emit(CustomersLoading());
    try {
      await customersRepository.updateCustomer(event.customerId, event.data);
      emit(CustomerOperationSuccess('Customer updated'));
      final customers = await customersRepository.getCustomers(page: 1, pageSize: _pageSize);
      _customers.clear();
      _customers.addAll(customers);
      emit(CustomersLoaded(
        customers,
        currentPage: 1,
        hasMore: customers.length >= _pageSize,
      ));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  Future<void> _onDeleteCustomer(DeleteCustomer event, Emitter<CustomersState> emit) async {
    emit(CustomersLoading());
    try {
      await customersRepository.deleteCustomer(event.customerId);
      emit(CustomerOperationSuccess('Customer deleted'));
      final customers = await customersRepository.getCustomers(page: 1, pageSize: _pageSize);
      _customers.clear();
      _customers.addAll(customers);
      emit(CustomersLoaded(
        customers,
        currentPage: 1,
        hasMore: customers.length >= _pageSize,
      ));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  // Case Notification Preferences
  Future<void> _onLoadCaseNotificationPreference(
      LoadCaseNotificationPreference event, Emitter<CustomersState> emit) async {
    emit(CustomersLoading());
    try {
      final preference =
          await customersRepository.getCaseNotificationPreference(event.caseCode);
      emit(CaseNotificationPreferenceLoaded(preference));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  Future<void> _onUpdateCaseNotificationPreference(
      UpdateCaseNotificationPreference event, Emitter<CustomersState> emit) async {
    try {
      final preference = await customersRepository.updateCaseNotificationPreference(
        event.caseCode,
        event.notificationsEnabled,
      );
      emit(CaseNotificationPreferenceUpdated(preference));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  // Payment Proofs
  Future<void> _onSubmitPaymentProof(
      SubmitPaymentProof event, Emitter<CustomersState> emit) async {
    emit(PaymentProofSubmitting());
    try {
      final proof = await customersRepository.submitPaymentProof(
        caseCode: event.caseCode,
        amount: event.amount,
        paymentDate: event.paymentDate,
        filePath: event.filePath,
        notes: event.notes,
      );
      emit(PaymentProofSubmitted(proof));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  // Requested Documents
  Future<void> _onLoadRequestedDocuments(
      LoadRequestedDocuments event, Emitter<CustomersState> emit) async {
    emit(CustomersLoading());
    try {
      final documents =
          await customersRepository.getRequestedDocuments(event.caseCode);
      emit(RequestedDocumentsLoaded(documents));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  Future<void> _onSubmitRequestedDocument(
      SubmitRequestedDocument event, Emitter<CustomersState> emit) async {
    emit(RequestedDocumentSubmitting());
    try {
      final document = await customersRepository.submitRequestedDocument(
        caseCode: event.caseCode,
        requestId: event.requestId,
        filePath: event.filePath,
        notes: event.notes,
      );
      emit(RequestedDocumentSubmitted(document));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }
}

