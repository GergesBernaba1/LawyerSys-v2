import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/tenant_model.dart';
import '../repositories/tenants_repository.dart';
import 'tenants_event.dart';
import 'tenants_state.dart';

class TenantsBloc extends Bloc<TenantsEvent, TenantsState> {
  final TenantsRepository tenantsRepository;

  TenantsBloc({required this.tenantsRepository}) : super(TenantsInitial()) {
    on<LoadTenants>(_onLoad);
    on<RefreshTenants>(_onRefresh);
    on<UpdateTenantStatus>(_onUpdateStatus);
    on<CreateTenant>(_onCreateTenant);
    on<UpdateTenant>(_onUpdateTenant);
    on<DeleteTenant>(_onDeleteTenant);
  }

  Future<void> _onLoad(LoadTenants event, Emitter<TenantsState> emit) async {
    emit(TenantsLoading());
    try {
      emit(TenantsLoaded(await _fetch()));
    } catch (e) {
      emit(TenantsError(e.toString()));
    }
  }

  Future<void> _onRefresh(RefreshTenants event, Emitter<TenantsState> emit) async {
    try {
      emit(TenantsLoaded(await _fetch()));
    } catch (e) {
      emit(TenantsError(e.toString()));
    }
  }

  Future<void> _onUpdateStatus(UpdateTenantStatus event, Emitter<TenantsState> emit) async {
    try {
      await tenantsRepository.updateTenantStatus(event.id, event.isActive);
      emit(TenantStatusUpdated('Tenant status updated'));
      emit(TenantsLoaded(await _fetch()));
    } catch (e) {
      emit(TenantsError(e.toString()));
    }
  }

  Future<void> _onCreateTenant(CreateTenant event, Emitter<TenantsState> emit) async {
    try {
      await tenantsRepository.createTenant(event.data);
      emit(TenantOperationSuccess('Tenant created successfully'));      emit(TenantsLoaded(await _fetch()));
    } catch (e) {
      emit(TenantsError(e.toString()));
    }
  }

  Future<void> _onUpdateTenant(UpdateTenant event, Emitter<TenantsState> emit) async {
    try {
      await tenantsRepository.updateTenant(event.id, event.data);
      emit(TenantOperationSuccess('Tenant updated successfully'));      emit(TenantsLoaded(await _fetch()));
    } catch (e) {
      emit(TenantsError(e.toString()));
    }
  }

  Future<void> _onDeleteTenant(DeleteTenant event, Emitter<TenantsState> emit) async {
    try {
      await tenantsRepository.deleteTenant(event.id);
      emit(TenantOperationSuccess('Tenant deleted successfully'));      emit(TenantsLoaded(await _fetch()));
    } catch (e) {
      emit(TenantsError(e.toString()));
    }
  }

  Future<TenantSelectionModel> _fetch() async {
    final raw = await tenantsRepository.getAvailableTenants();
    return TenantSelectionModel(
      currentTenantId: raw.currentTenantId,
      isSuperAdmin: raw.isSuperAdmin,
      tenants: raw.items.map((item) => TenantModel.fromJson(
        item,
        currentTenantId: raw.currentTenantId,
      )).toList(),
    );
  }
}
