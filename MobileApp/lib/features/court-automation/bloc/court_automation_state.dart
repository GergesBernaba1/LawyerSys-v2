import '../models/court_automation_models.dart';

abstract class CourtAutoState {}

class CourtAutoInitial extends CourtAutoState {}

class CourtAutoLoading extends CourtAutoState {}

class AutomationPacksLoaded extends CourtAutoState {
  final List<AutomationPack> packs;
  AutomationPacksLoaded(this.packs);
}

class DeadlinesCalculated extends CourtAutoState {
  final List<DeadlineItem> deadlines;
  final String packKey;
  DeadlinesCalculated(this.deadlines, {required this.packKey});
}

class FilingSubmitted extends CourtAutoState {
  final FilingSubmission submission;
  FilingSubmitted(this.submission);
}

class FilingsLoaded extends CourtAutoState {
  final List<FilingSubmission> filings;
  FilingsLoaded(this.filings);
}

class CourtAutoError extends CourtAutoState {
  final String message;
  CourtAutoError(this.message);
}
