import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/document-generation/bloc/doc_generation_event.dart';
import 'package:qadaya_lawyersys/features/document-generation/bloc/doc_generation_state.dart';
import 'package:qadaya_lawyersys/features/document-generation/repositories/doc_generation_repository.dart';

class DocGenerationBloc extends Bloc<DocGenerationEvent, DocGenState> {

  DocGenerationBloc({required this.repository}) : super(DocGenInitial()) {
    on<LoadDocTemplates>(_onLoadDocTemplates);
    on<GenerateDocument>(_onGenerateDocument);
    on<LoadDocHistory>(_onLoadDocHistory);
    on<LoadDocDrafts>(_onLoadDocDrafts);
    on<CreateDocDraft>(_onCreateDocDraft);
    on<DeleteDocDraft>(_onDeleteDocDraft);
  }
  final DocGenerationRepository repository;

  Future<void> _onLoadDocTemplates(
      LoadDocTemplates event, Emitter<DocGenState> emit,) async {
    emit(DocGenLoading());
    try {
      final templates = await repository.getTemplates(language: event.language);
      emit(DocTemplatesLoaded(templates));
    } catch (e) {
      emit(DocGenError(e.toString()));
    }
  }

  Future<void> _onGenerateDocument(
      GenerateDocument event, Emitter<DocGenState> emit,) async {
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
      LoadDocHistory event, Emitter<DocGenState> emit,) async {
    emit(DocGenLoading());
    try {
      final history = await repository.getHistory(caseCode: event.caseCode);
      emit(DocHistoryLoaded(history));
    } catch (e) {
      emit(DocGenError(e.toString()));
    }
  }

  Future<void> _onLoadDocDrafts(
      LoadDocDrafts event, Emitter<DocGenState> emit,) async {
    emit(DocGenLoading());
    try {
      final drafts = await repository.getDrafts();
      emit(DocDraftsLoaded(drafts));
    } catch (e) {
      emit(DocGenError(e.toString()));
    }
  }

  Future<void> _onCreateDocDraft(
      CreateDocDraft event, Emitter<DocGenState> emit,) async {
    emit(DocGenLoading());
    try {
      await repository.createDraft(
        title: event.title,
        content: event.content,
        templateId: event.templateId,
      );
      emit(DocGenOperationSuccess('Draft created successfully'));
      if (!isClosed) add(LoadDocDrafts());
    } catch (e) {
      emit(DocGenError(e.toString()));
    }
  }

  Future<void> _onDeleteDocDraft(
      DeleteDocDraft event, Emitter<DocGenState> emit,) async {
    emit(DocGenLoading());
    try {
      await repository.deleteDraft(event.id);
      emit(DocGenOperationSuccess('Draft deleted successfully'));
      if (!isClosed) add(LoadDocDrafts());
    } catch (e) {
      emit(DocGenError(e.toString()));
    }
  }
}
