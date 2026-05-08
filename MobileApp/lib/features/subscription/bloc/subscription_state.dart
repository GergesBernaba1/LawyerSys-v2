import 'package:qadaya_lawyersys/features/subscription/models/subscription_package.dart';
import 'package:qadaya_lawyersys/features/subscription/models/tenant_subscription.dart';

abstract class SubscriptionState {}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {

  SubscriptionLoaded(this.packages, {this.currentSubscription});
  final List<SubscriptionPackage> packages;
  final TenantSubscription? currentSubscription;
}

class SubscriptionError extends SubscriptionState {

  SubscriptionError(this.message);
  final String message;
}
