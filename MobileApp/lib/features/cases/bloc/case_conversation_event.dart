abstract class CaseConversationEvent {}

class LoadCaseConversation extends CaseConversationEvent {
  LoadCaseConversation(this.caseCode);
  final String caseCode;
}

class SendCaseMessage extends CaseConversationEvent {
  SendCaseMessage({
    required this.caseCode,
    required this.message,
    required this.visibleToCustomer,
  });
  final String caseCode;
  final String message;
  final bool visibleToCustomer;
}
