import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/subscription_repository.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository repository;

  SubscriptionBloc({required this.repository}) : super(SubscriptionInitial()) {
    on<LoadSubscriptionPackages>(_onLoadPackages);
    on<RefreshSubscriptionPackages>(_onRefreshPackages);
  }

  Future<void> _onLoadPackages(
      LoadSubscriptionPackages event, Emitter<SubscriptionState> emit) async {
    emit(SubscriptionLoading());
    try {
      final packages = await repository.getPublicPackages();
      emit(SubscriptionLoaded(packages));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onRefreshPackages(
      RefreshSubscriptionPackages event, Emitter<SubscriptionState> emit) async {
    try {
      final packages = await repository.getPublicPackages();
      emit(SubscriptionLoaded(packages));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }
}
