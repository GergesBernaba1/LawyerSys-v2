import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/judicial_documents_repository.dart';
import 'judicial_documents_event.dart';
import 'judicial_documents_state.dart';

class JudicialDocumentsBloc extends Bloc<JudicialDocumentsEvent, JudicialDocumentsState> {
  final JudicialDocumentsRepository repository;

  static const int _pageSize = 20;

  JudicialDocumentsBloc({required this.repository}) : super(JudicialDocumentsInitial()) {
    on<LoadJudicialDocuments>(_onLoad);
    on<RefreshJudicialDocuments>(_onRefresh);
    on<SearchJudicialDocuments>(_onSearch);
    on<CreateJudicialDocument>(_onCreate);
    on<UpdateJudicialDocument>(_onUpdate);
    on<DeleteJudicialDocument>(_onDelete);
  }

  Future<void> _onLoad(LoadJudicialDocuments event, Emitter<JudicialDocumentsState> emit) async {
    emit(JudicialDocumentsLoading());
    try {
      final result = await repository.getDocuments(
        page: event.page,
        pageSize: _pageSize,
        search: event.search,
      );
      emit(JudicialDocumentsLoaded(
        documents: result.items,
        totalCount: result.totalCount,
        page: event.page,
        search: event.search,
      ));
    } catch (e) {
      emit(JudicialDocumentsError(e.toString()));
    }
  }

  Future<void> _onRefresh(RefreshJudicialDocuments event, Emitter<JudicialDocumentsState> emit) async {
    final current = state is JudicialDocumentsLoaded ? state as JudicialDocumentsLoaded : null;
    try {
      final result = await repository.getDocuments(
        page: current?.page ?? 1,
        pageSize: _pageSize,
        search: current?.search,
      );
      emit(JudicialDocumentsLoaded(
        documents: result.items,
        totalCount: result.totalCount,
        page: current?.page ?? 1,
        search: current?.search,
      ));
    } catch (e) {
      emit(JudicialDocumentsError(e.toString()));
    }
  }

  Future<void> _onSearch(SearchJudicialDocuments event, Emitter<JudicialDocumentsState> emit) async {
    emit(JudicialDocumentsLoading());
    try {
      final result = await repository.getDocuments(
        page: 1,
        pageSize: _pageSize,
        search: event.query.isEmpty ? null : event.query,
      );
      emit(JudicialDocumentsLoaded(
        documents: result.items,
        totalCount: result.totalCount,
        page: 1,
        search: event.query.isEmpty ? null : event.query,
      ));
    } catch (e) {
      emit(JudicialDocumentsError(e.toString()));
    }
  }

  Future<void> _onCreate(CreateJudicialDocument event, Emitter<JudicialDocumentsState> emit) async {
    try {
      await repository.create(event.payload);
      emit(JudicialDocumentActionSuccess('Document created'));
      if (!isClosed) add(LoadJudicialDocuments());
    } catch (e) {
      emit(JudicialDocumentsError(e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateJudicialDocument event, Emitter<JudicialDocumentsState> emit) async {
    try {
      await repository.update(event.id, event.payload);
      emit(JudicialDocumentActionSuccess('Document updated'));
      if (!isClosed) {
        final current = state is JudicialDocumentsLoaded ? state as JudicialDocumentsLoaded : null;
        add(LoadJudicialDocuments(page: current?.page ?? 1, search: current?.search));
      }
    } catch (e) {
      emit(JudicialDocumentsError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteJudicialDocument event, Emitter<JudicialDocumentsState> emit) async {
    try {
      await repository.delete(event.id);
      emit(JudicialDocumentActionSuccess('Document deleted'));
      if (!isClosed) add(RefreshJudicialDocuments());
    } catch (e) {
      emit(JudicialDocumentsError(e.toString()));
    }
  }
}
