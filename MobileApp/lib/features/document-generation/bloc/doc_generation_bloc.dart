import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/doc_generation_repository.dart';
import 'doc_generation_event.dart';
import 'doc_generation_state.dart';

class DocGenerationBloc extends Bloc<DocGenerationEvent, DocGenState> {
  final DocGenerationRepository repository;

  DocGenerationBloc({required this.repository}) : super(DocGenInitial()) {
    on<LoadDocTemplates>(_onLoadDocTemplates);
    on<GenerateDocument>(_onGenerateDocument);
    on<LoadDocHistory>(_onLoadDocHistory);
    on<LoadDocDrafts>(_onLoadDocDrafts);
    on<CreateDocDraft>(_onCreateDocDraft);
    on<DeleteDocDraft>(_onDeleteDocDraft);
  }

  Future<void> _onLoadDocTemplates(
      LoadDocTemplates event, Emitter<DocGenState> emit) async {
    emit(DocGenLoading());
    try {
      final templates = await repository.getTemplates(language: event.language);
      emit(DocTemplatesLoaded(templates));
    } catch (e) {
      emit(DocGenError(e.toString()));
    }
  }

  Future<void> _onGenerateDocument(
      GenerateDocument event, Emitter<DocGenState> emit) async {
    emit(DocGenLoading());
    try {
      final doc = await repository.generateDocument(
        templateId: event.templateId,
        fieldValues: event.fieldValues,
        language: event.language,
        caseCode: event.caseCode,
      );
      emit(DocGeneratedSuccess(doc));
    } catch (e) {
      emit(DocGenError(e.toString()));
    }
  }

  Future<void> _onLoadDocHistory(
      LoadDocHistory event, Emitter<DocGenState> emit) async {
    emit(DocGenLoading());
    try {
      final history = await repository.getHistory(caseCode: event.caseCode);
      emit(DocHistoryLoaded(history));
    } catch (e) {
      emit(DocGenError(e.toString()));
    }
  }

  Future<void> _onLoadDocDrafts(
      LoadDocDrafts event, Emitter<DocGenState> emit) async {
    emit(DocGenLoading());
    try {
      final drafts = await repository.getDrafts();
      emit(DocDraftsLoaded(drafts));
    } catch (e) {
      emit(DocGenError(e.toString()));
    }
  }

  Future<void> _onCreateDocDraft(
      CreateDocDraft event, Emitter<DocGenState> emit) async {
    emit(DocGenLoading());
    try {
      await repository.createDraft(
        title: event.title,
        content: event.content,
        templateId: event.templateId,
      );
      emit(DocGenOperationSuccess('Draft created successfully'));
      add(LoadDocDrafts());
    } catch (e) {
      emit(DocGenError(e.toString()));
    }
  }

  Future<void> _onDeleteDocDraft(
      DeleteDocDraft event, Emitter<DocGenState> emit) async {
    emit(DocGenLoading());
    try {
      await repository.deleteDraft(event.id);
      emit(DocGenOperationSuccess('Draft deleted successfully'));
      add(LoadDocDrafts());
    } catch (e) {
      emit(DocGenError(e.toString()));
    }
  }
}
