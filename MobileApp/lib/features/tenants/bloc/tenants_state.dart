import 'package:qadaya_lawyersys/features/tenants/models/tenant_model.dart';

abstract class TenantsState {}

class TenantsInitial extends TenantsState {}

class TenantsLoading extends TenantsState {}

class TenantsLoaded extends TenantsState {
  TenantsLoaded(this.selection);
  final TenantSelectionModel selection;
}

class TenantsError extends TenantsState {
  TenantsError(this.message);
  final String message;
}

class TenantStatusUpdated extends TenantsState {
  TenantStatusUpdated(this.message);
  final String message;
}

class TenantOperationSuccess extends TenantsState {
  TenantOperationSuccess(this.message);
  final String message;
}
