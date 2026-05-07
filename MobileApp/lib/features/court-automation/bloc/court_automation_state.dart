import 'package:qadaya_lawyersys/features/court-automation/models/court_automation_models.dart';

abstract class CourtAutoState {}

class CourtAutoInitial extends CourtAutoState {}

class CourtAutoLoading extends CourtAutoState {}

class AutomationPacksLoaded extends CourtAutoState {
  AutomationPacksLoaded(this.packs);
  final List<AutomationPack> packs;
}

class DeadlinesCalculated extends CourtAutoState {
  DeadlinesCalculated(this.deadlines, {required this.packKey});
  final List<DeadlineItem> deadlines;
  final String packKey;
}

class FilingSubmitted extends CourtAutoState {
  FilingSubmitted(this.submission);
  final FilingSubmission submission;
}

class FilingsLoaded extends CourtAutoState {
  FilingsLoaded(this.filings);
  final List<FilingSubmission> filings;
}

class CourtAutoError extends CourtAutoState {
  CourtAutoError(this.message);
  final String message;
}
