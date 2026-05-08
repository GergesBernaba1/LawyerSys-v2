abstract class CaseConversationState {}

class CaseConversationInitial extends CaseConversationState {}

class CaseConversationLoading extends CaseConversationState {}

class CaseConversationSending extends CaseConversationState {}

class CaseConversationLoaded extends CaseConversationState {
  CaseConversationLoaded(this.messages);
  final List<Map<String, dynamic>> messages;
}

class CaseMessageSent extends CaseConversationState {}

class CaseConversationError extends CaseConversationState {
  CaseConversationError(this.message);
  final String message;
}
