import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/subscription/bloc/subscription_event.dart';
import 'package:qadaya_lawyersys/features/subscription/bloc/subscription_state.dart';
import 'package:qadaya_lawyersys/features/subscription/repositories/subscription_repository.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {

  SubscriptionBloc({required this.repository}) : super(SubscriptionInitial()) {
    on<LoadSubscriptionPackages>(_onLoadPackages);
    on<RefreshSubscriptionPackages>(_onRefreshPackages);
  }
  final SubscriptionRepository repository;

  Future<void> _onLoadPackages(
      LoadSubscriptionPackages event, Emitter<SubscriptionState> emit,) async {
    emit(SubscriptionLoading());
    try {
      final packages = await repository.getPublicPackages();
      emit(SubscriptionLoaded(packages));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onRefreshPackages(
      RefreshSubscriptionPackages event, Emitter<SubscriptionState> emit,) async {
    try {
      final packages = await repository.getPublicPackages();
      emit(SubscriptionLoaded(packages));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }
}
