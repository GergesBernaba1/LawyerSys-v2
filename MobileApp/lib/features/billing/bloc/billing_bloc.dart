import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/billing.dart';
import '../repositories/billing_repository.dart';
import 'billing_event.dart';
import 'billing_state.dart';

class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final BillingRepository billingRepository;

  BillingBloc({required this.billingRepository})
      : super(BillingInitial()) {
    on<LoadPayments>(_onLoadPayments);
    on<LoadReceipts>(_onLoadReceipts);
    on<LoadCustomers>(_onLoadCustomers);
    on<LoadEmployees>(_onLoadEmployees);
    on<LoadSummary>(_onLoadSummary);
    on<CreatePayment>(_onCreatePayment);
    on<CreateReceipt>(_onCreateReceipt);
    on<DeletePayment>(_onDeletePayment);
    on<DeleteReceipt>(_onDeleteReceipt);
  }

  Future<void> _onLoadPayments(
      LoadPayments event, Emitter<BillingState> emit) async {
    if (state is! BillingLoading) {
      emit(BillingLoading());
    }
    try {
      final payments = await billingRepository.getPayments();
      emit(_updateState(payments: payments));
    } catch (e) {
      emit(BillingError(e.toString()));
    }
  }

  Future<void> _onLoadReceipts(
      LoadReceipts event, Emitter<BillingState> emit) async {
    if (state is! BillingLoading) {
      emit(BillingLoading());
    }
    try {
      final receipts = await billingRepository.getReceipts();
      emit(_updateState(receipts: receipts));
    } catch (e) {
      emit(BillingError(e.toString()));
    }
  }

  Future<void> _onLoadCustomers(
      LoadCustomers event, Emitter<BillingState> emit) async {
    if (state is! BillingLoading) {
      emit(BillingLoading());
    }
    try {
      final customers = await billingRepository.getCustomers();
      emit(_updateState(customers: customers));
    } catch (e) {
      emit(BillingError(e.toString()));
    }
  }

  Future<void> _onLoadEmployees(
      LoadEmployees event, Emitter<BillingState> emit) async {
    if (state is! BillingLoading) {
      emit(BillingLoading());
    }
    try {
      final employees = await billingRepository.getEmployees();
      emit(_updateState(employees: employees));
    } catch (e) {
      emit(BillingError(e.toString()));
    }
  }

  Future<void> _onLoadSummary(
      LoadSummary event, Emitter<BillingState> emit) async {
    if (state is! BillingLoading) {
      emit(BillingLoading());
    }
    try {
      final summary = await billingRepository.getSummary();
      emit(_updateState(summary: summary));
    } catch (e) {
      emit(BillingError(e.toString()));
    }
  }

  Future<void> _onCreatePayment(
      CreatePayment event, Emitter<BillingState> emit) async {
    try {
      await billingRepository.createPayment(event.payment);
      add(LoadPayments());
      add(LoadSummary());
    } catch (e) {
      emit(BillingError(e.toString()));
    }
  }

  Future<void> _onCreateReceipt(
      CreateReceipt event, Emitter<BillingState> emit) async {
    try {
      await billingRepository.createReceipt(event.receipt);
      add(LoadReceipts());
      add(LoadSummary());
    } catch (e) {
      emit(BillingError(e.toString()));
    }
  }

  Future<void> _onDeletePayment(
      DeletePayment event, Emitter<BillingState> emit) async {
    try {
      await billingRepository.deletePayment(event.id);
      add(LoadPayments());
      add(LoadSummary());
    } catch (e) {
      emit(BillingError(e.toString()));
    }
  }

  Future<void> _onDeleteReceipt(
      DeleteReceipt event, Emitter<BillingState> emit) async {
    try {
      await billingRepository.deleteReceipt(event.id);
      add(LoadReceipts());
      add(LoadSummary());
    } catch (e) {
      emit(BillingError(e.toString()));
    }
  }

  BillingState _updateState({
    List<BillingPay>? payments,
    List<BillingReceipt>? receipts,
    List<CustomerItem>? customers,
    List<EmployeeItem>? employees,
    BillingSummary? summary,
  }) {
    if (state is BillingLoaded) {
      final currentState = state as BillingLoaded;
      return BillingLoaded(
        payments: payments ?? currentState.payments,
        receipts: receipts ?? currentState.receipts,
        customers: customers ?? currentState.customers,
        employees: employees ?? currentState.employees,
        summary: summary ?? currentState.summary,
      );
    }
    return BillingLoaded(
      payments: payments ?? [],
      receipts: receipts ?? [],
      customers: customers ?? [],
      employees: employees ?? [],
      summary: summary,
    );
  }
}