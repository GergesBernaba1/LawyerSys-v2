abstract class IntakeEvent {}

class LoadIntakeLeads extends IntakeEvent {
  final String? status;
  final String? search;
  LoadIntakeLeads({this.status, this.search});
}

class RefreshIntakeLeads extends IntakeEvent {}

class SearchIntakeLeads extends IntakeEvent {
  final String query;
  SearchIntakeLeads(this.query);
}

class FilterIntakeByStatus extends IntakeEvent {
  final String? status;
  FilterIntakeByStatus(this.status);
}

class RunIntakeConflictCheck extends IntakeEvent {
  final int id;
  RunIntakeConflictCheck(this.id);
}

class QualifyIntakeLead extends IntakeEvent {
  final int id;
  final bool isQualified;
  final String? notes;
  QualifyIntakeLead(this.id, {required this.isQualified, this.notes});
}

class AssignIntakeLead extends IntakeEvent {
  final int id;
  final int assignedEmployeeId;
  final DateTime? nextFollowUpAt;
  AssignIntakeLead(this.id,
      {required this.assignedEmployeeId, this.nextFollowUpAt});
}

class ConvertIntakeLead extends IntakeEvent {
  final int id;
  final String? caseType;
  final int? initialAmount;
  ConvertIntakeLead(this.id, {this.caseType, this.initialAmount});
}

class CreatePublicIntakeLead extends IntakeEvent {
  final Map<String, dynamic> payload;
  CreatePublicIntakeLead(this.payload);
}
