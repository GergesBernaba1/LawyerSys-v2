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
