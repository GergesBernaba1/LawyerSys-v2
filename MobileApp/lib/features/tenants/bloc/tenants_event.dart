abstract class TenantsEvent {}

class LoadTenants extends TenantsEvent {}

class RefreshTenants extends TenantsEvent {}

class UpdateTenantStatus extends TenantsEvent {
  UpdateTenantStatus(this.id, {required this.isActive});
  final int id;
  final bool isActive;
}

class CreateTenant extends TenantsEvent {
  CreateTenant(this.data);
  final Map<String, dynamic> data;
}

class UpdateTenant extends TenantsEvent {
  UpdateTenant(this.id, this.data);
  final int id;
  final Map<String, dynamic> data;
}

class DeleteTenant extends TenantsEvent {
  DeleteTenant(this.id);
  final int id;
}
