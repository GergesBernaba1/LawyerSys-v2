import '../models/tenant_model.dart';

abstract class TenantsState {}

class TenantsInitial extends TenantsState {}

class TenantsLoading extends TenantsState {}

class TenantsLoaded extends TenantsState {
  final TenantSelectionModel selection;
  TenantsLoaded(this.selection);
}

class TenantsError extends TenantsState {
  final String message;
  TenantsError(this.message);
}

class TenantStatusUpdated extends TenantsState {
  final String message;
  TenantStatusUpdated(this.message);
}

class TenantOperationSuccess extends TenantsState {
  final String message;
  TenantOperationSuccess(this.message);
}
