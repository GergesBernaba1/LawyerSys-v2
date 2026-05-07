import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/esign/bloc/esign_event.dart';
import 'package:qadaya_lawyersys/features/esign/bloc/esign_state.dart';
import 'package:qadaya_lawyersys/features/esign/repositories/esign_repository.dart';

class ESignBloc extends Bloc<ESignEvent, ESignState> {

  ESignBloc({required this.repository}) : super(ESignInitial()) {
    on<LoadESignRequests>(_onLoadESignRequests);
    on<RefreshESignRequests>(_onRefreshESignRequests);
    on<CreateESignRequest>(_onCreateESignRequest);
    on<UpdateESignStatus>(_onUpdateESignStatus);
    on<GetESignShareLink>(_onGetESignShareLink);
  }
  final ESignRepository repository;

  // Keep track of the last filter so refresh can reuse it
  String? _lastStatus;
  String? _lastSearch;

  Future<void> _onLoadESignRequests(
    LoadESignRequests event,
    Emitter<ESignState> emit,
  ) async {
    _lastStatus = event.status;
    _lastSearch = event.search;
    emit(ESignLoading());
    try {
      final requests = await repository.getRequests(
        status: event.status,
        search: event.search,
      );
      emit(ESignLoaded(requests));
    } catch (e) {
      emit(ESignError(e.toString()));
    }
  }

  Future<void> _onRefreshESignRequests(
    RefreshESignRequests event,
    Emitter<ESignState> emit,
  ) async {
    emit(ESignLoading());
    try {
      final requests = await repository.getRequests(
        status: _lastStatus,
        search: _lastSearch,
      );
      emit(ESignLoaded(requests));
    } catch (e) {
      emit(ESignError(e.toString()));
    }
  }

  Future<void> _onCreateESignRequest(
    CreateESignRequest event,
    Emitter<ESignState> emit,
  ) async {
    try {
      await repository.createRequest(
        title: event.title,
        documentContent: event.documentContent,
        signerEmails: event.signerEmails,
        expiresAt: event.expiresAt,
      );
      emit(ESignOperationSuccess('E-Sign request created successfully'));
      final requests = await repository.getRequests(
        status: _lastStatus,
        search: _lastSearch,
      );
      emit(ESignLoaded(requests));
    } catch (e) {
      emit(ESignError(e.toString()));
    }
  }

  Future<void> _onUpdateESignStatus(
    UpdateESignStatus event,
    Emitter<ESignState> emit,
  ) async {
    try {
      await repository.updateStatus(event.id, event.status);
      emit(ESignOperationSuccess('Status updated successfully'));
      final requests = await repository.getRequests(
        status: _lastStatus,
        search: _lastSearch,
      );
      emit(ESignLoaded(requests));
    } catch (e) {
      emit(ESignError(e.toString()));
    }
  }

  Future<void> _onGetESignShareLink(
    GetESignShareLink event,
    Emitter<ESignState> emit,
  ) async {
    try {
      final url = await repository.getShareLink(event.id);
      emit(ESignShareLinkReady(url));
    } catch (e) {
      emit(ESignError(e.toString()));
    }
  }
}
