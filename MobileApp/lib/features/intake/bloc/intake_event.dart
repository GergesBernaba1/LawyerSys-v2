abstract class IntakeEvent {}

class LoadIntakeLeads extends IntakeEvent {
  LoadIntakeLeads({this.status, this.search});
  final String? status;
  final String? search;
}

class RefreshIntakeLeads extends IntakeEvent {}

class SearchIntakeLeads extends IntakeEvent {
  SearchIntakeLeads(this.query);
  final String query;
}

class FilterIntakeByStatus extends IntakeEvent {
  FilterIntakeByStatus(this.status);
  final String? status;
}

class RunIntakeConflictCheck extends IntakeEvent {
  RunIntakeConflictCheck(this.id);
  final int id;
}

class QualifyIntakeLead extends IntakeEvent {
  QualifyIntakeLead(this.id, {required this.isQualified, this.notes});
  final int id;
  final bool isQualified;
  final String? notes;
}

class AssignIntakeLead extends IntakeEvent {
  AssignIntakeLead(this.id,
      {required this.assignedEmployeeId, this.nextFollowUpAt,});
  final int id;
  final int assignedEmployeeId;
  final DateTime? nextFollowUpAt;
}

class ConvertIntakeLead extends IntakeEvent {
  ConvertIntakeLead(this.id, {this.caseType, this.initialAmount});
  final int id;
  final String? caseType;
  final int? initialAmount;
}

class CreatePublicIntakeLead extends IntakeEvent {
  CreatePublicIntakeLead(this.payload);
  final Map<String, dynamic> payload;
}
