import '../models/subscription_package.dart';

abstract class SubscriptionState {}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {
  final List<SubscriptionPackage> packages;

  SubscriptionLoaded(this.packages);
}

class SubscriptionError extends SubscriptionState {
  final String message;

  SubscriptionError(this.message);
}
