import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/case_conversation_event.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/case_conversation_state.dart';
import 'package:qadaya_lawyersys/features/cases/repositories/case_conversation_repository.dart';

class CaseConversationBloc
    extends Bloc<CaseConversationEvent, CaseConversationState> {
  CaseConversationBloc({required this.repository})
      : super(CaseConversationInitial()) {
    on<LoadCaseConversation>(_onLoad);
    on<SendCaseMessage>(_onSend);
  }

  final CaseConversationRepository repository;

  Future<void> _onLoad(
    LoadCaseConversation event,
    Emitter<CaseConversationState> emit,
  ) async {
    emit(CaseConversationLoading());
    try {
      final messages = await repository.getMessages(event.caseCode);
      emit(CaseConversationLoaded(messages));
    } catch (err) {
      emit(CaseConversationError(err.toString()));
    }
  }

  Future<void> _onSend(
    SendCaseMessage event,
    Emitter<CaseConversationState> emit,
  ) async {
    emit(CaseConversationSending());
    try {
      await repository.sendMessage(
        caseCode: event.caseCode,
        message: event.message,
        visibleToCustomer: event.visibleToCustomer,
      );
      emit(CaseMessageSent());
    } catch (err) {
      emit(CaseConversationError(err.toString()));
    }
  }
}
