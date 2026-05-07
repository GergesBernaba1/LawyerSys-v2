abstract class CourtAutomationEvent {}

class LoadAutomationPacks extends CourtAutomationEvent {
  LoadAutomationPacks({this.language});
  final String? language;
}

class CalculateDeadlines extends CourtAutomationEvent {

  CalculateDeadlines({
    required this.packKey,
    required this.filingDate,
  });
  final String packKey;
  final String filingDate;
}

class SubmitFiling extends CourtAutomationEvent {

  SubmitFiling({
    required this.caseCode,
    required this.packKey,
    required this.formData,
  });
  final String caseCode;
  final String packKey;
  final Map<String, dynamic> formData;
}

class LoadFilings extends CourtAutomationEvent {
  LoadFilings({this.caseCode});
  final String? caseCode;
}
