import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/trust_accounting_repository.dart';
import 'trust_accounting_event.dart';
import 'trust_accounting_state.dart';

class TrustAccountingBloc extends Bloc<TrustAccountingEvent, TrustAccountingState> {
  final TrustAccountingRepository trustAccountingRepository;

  TrustAccountingBloc({required this.trustAccountingRepository}) : super(TrustAccountingInitial()) {
    on<LoadTrustTransactions>(_onLoadTrustTransactions);
    on<RefreshTrustTransactions>(_onRefreshTrustTransactions);
    on<SearchTrustTransactions>(_onSearchTrustTransactions);
    on<SelectTrustTransaction>(_onSelectTrustTransaction);
    on<CreateTrustTransaction>(_onCreateTrustTransaction);
    on<UpdateTrustTransaction>(_onUpdateTrustTransaction);
    on<DeleteTrustTransaction>(_onDeleteTrustTransaction);
  }

  Future<void> _onLoadTrustTransactions(LoadTrustTransactions event, Emitter<TrustAccountingState> emit) async {
    emit(TrustAccountingLoading());
    try {
      final txs = await trustAccountingRepository.getTransactions();
      emit(TrustAccountingLoaded(txs));
    } catch (e) {
      emit(TrustAccountingError(e.toString()));
    }
  }

  Future<void> _onRefreshTrustTransactions(RefreshTrustTransactions event, Emitter<TrustAccountingState> emit) async {
    try {
      final txs = await trustAccountingRepository.getTransactions();
      emit(TrustAccountingLoaded(txs));
    } catch (e) {
      emit(TrustAccountingError(e.toString()));
    }
  }

  Future<void> _onSearchTrustTransactions(SearchTrustTransactions event, Emitter<TrustAccountingState> emit) async {
    emit(TrustAccountingLoading());
    try {
      final txs = await trustAccountingRepository.searchTransactions(event.query);
      emit(TrustAccountingLoaded(txs));
    } catch (e) {
      emit(TrustAccountingError(e.toString()));
    }
  }

  Future<void> _onSelectTrustTransaction(SelectTrustTransaction event, Emitter<TrustAccountingState> emit) async {
    emit(TrustAccountingLoading());
    try {
      final tx = await trustAccountingRepository.getTransactionById(event.transactionId);
      if (tx != null) {
        emit(TrustTransactionDetailLoaded(tx));
      } else {
        emit(TrustAccountingError('Transaction not found'));
      }
    } catch (e) {
      emit(TrustAccountingError(e.toString()));
    }
  }

  Future<void> _onCreateTrustTransaction(CreateTrustTransaction event, Emitter<TrustAccountingState> emit) async {
    emit(TrustAccountingLoading());
    try {
      final created = await trustAccountingRepository.createTransaction(event.transaction);
      emit(TrustTransactionOperationSuccess('Transaction created: ${created.transactionId}'));
      final txs = await trustAccountingRepository.getTransactions();
      emit(TrustAccountingLoaded(txs));
    } catch (e) {
      emit(TrustAccountingError(e.toString()));
    }
  }

  Future<void> _onUpdateTrustTransaction(UpdateTrustTransaction event, Emitter<TrustAccountingState> emit) async {
    emit(TrustAccountingLoading());
    try {
      final updated = await trustAccountingRepository.updateTransaction(event.transaction);
      emit(TrustTransactionOperationSuccess('Transaction updated: ${updated.transactionId}'));
      final txs = await trustAccountingRepository.getTransactions();
      emit(TrustAccountingLoaded(txs));
    } catch (e) {
      emit(TrustAccountingError(e.toString()));
    }
  }

  Future<void> _onDeleteTrustTransaction(DeleteTrustTransaction event, Emitter<TrustAccountingState> emit) async {
    emit(TrustAccountingLoading());
    try {
      await trustAccountingRepository.deleteTransaction(event.transactionId);
      emit(TrustTransactionOperationSuccess('Transaction deleted'));  
      final txs = await trustAccountingRepository.getTransactions();
      emit(TrustAccountingLoaded(txs));
    } catch (e) {
      emit(TrustAccountingError(e.toString()));
    }
  }
}
