abstract class TenantsEvent {}

class LoadTenants extends TenantsEvent {}

class RefreshTenants extends TenantsEvent {}

class UpdateTenantStatus extends TenantsEvent {
  final int id;
  final bool isActive;
  UpdateTenantStatus(this.id, this.isActive);
}

class CreateTenant extends TenantsEvent {
  final Map<String, dynamic> data;
  CreateTenant(this.data);
}

class UpdateTenant extends TenantsEvent {
  final int id;
  final Map<String, dynamic> data;
  UpdateTenant(this.id, this.data);
}

class DeleteTenant extends TenantsEvent {
  final int id;
  DeleteTenant(this.id);
}
