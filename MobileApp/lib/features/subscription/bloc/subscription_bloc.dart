import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/subscription/bloc/subscription_event.dart';
import 'package:qadaya_lawyersys/features/subscription/bloc/subscription_state.dart';
import 'package:qadaya_lawyersys/features/subscription/models/subscription_package.dart';
import 'package:qadaya_lawyersys/features/subscription/repositories/subscription_repository.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {

  SubscriptionBloc({required this.repository}) : super(SubscriptionInitial()) {
    on<LoadSubscriptionPackages>(_onLoadPackages);
    on<RefreshSubscriptionPackages>(_onRefreshPackages);
    on<LoadCurrentSubscription>(_onLoadCurrentSubscription);
  }
  final SubscriptionRepository repository;

  Future<void> _onLoadPackages(
      LoadSubscriptionPackages event, Emitter<SubscriptionState> emit,) async {
    emit(SubscriptionLoading());
    try {
      final packages = await repository.getPublicPackages();
      final current = await repository.getCurrentSubscription();
      emit(SubscriptionLoaded(packages, currentSubscription: current));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onRefreshPackages(
      RefreshSubscriptionPackages event, Emitter<SubscriptionState> emit,) async {
    try {
      final packages = await repository.getPublicPackages();
      final current = await repository.getCurrentSubscription();
      emit(SubscriptionLoaded(packages, currentSubscription: current));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onLoadCurrentSubscription(
      LoadCurrentSubscription event, Emitter<SubscriptionState> emit,) async {
    try {
      final current = await repository.getCurrentSubscription();
      final prev = state;
      final packages =
          prev is SubscriptionLoaded ? prev.packages : <SubscriptionPackage>[];
      emit(SubscriptionLoaded(packages, currentSubscription: current));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }
}
