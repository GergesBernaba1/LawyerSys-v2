abstract class CourtAutomationEvent {}

class LoadAutomationPacks extends CourtAutomationEvent {
  final String? language;
  LoadAutomationPacks({this.language});
}

class CalculateDeadlines extends CourtAutomationEvent {
  final String packKey;
  final String filingDate;

  CalculateDeadlines({
    required this.packKey,
    required this.filingDate,
  });
}

class SubmitFiling extends CourtAutomationEvent {
  final String caseCode;
  final String packKey;
  final Map<String, dynamic> formData;

  SubmitFiling({
    required this.caseCode,
    required this.packKey,
    required this.formData,
  });
}

class LoadFilings extends CourtAutomationEvent {
  final String? caseCode;
  LoadFilings({this.caseCode});
}
