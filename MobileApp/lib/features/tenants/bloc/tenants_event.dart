abstract class TenantsEvent {}

class LoadTenants extends TenantsEvent {}

class RefreshTenants extends TenantsEvent {}

class UpdateTenantStatus extends TenantsEvent {
  final int id;
  final bool isActive;
  UpdateTenantStatus(this.id, this.isActive);
}
