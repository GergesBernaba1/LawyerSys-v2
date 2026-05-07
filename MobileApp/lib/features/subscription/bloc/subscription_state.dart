import 'package:qadaya_lawyersys/features/subscription/models/subscription_package.dart';

abstract class SubscriptionState {}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {

  SubscriptionLoaded(this.packages);
  final List<SubscriptionPackage> packages;
}

class SubscriptionError extends SubscriptionState {

  SubscriptionError(this.message);
  final String message;
}
