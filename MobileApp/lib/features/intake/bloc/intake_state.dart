import 'package:qadaya_lawyersys/features/intake/models/intake_form.dart';

abstract class IntakeState {}

class IntakeInitial extends IntakeState {}

class IntakeLoading extends IntakeState {}

class IntakeLoaded extends IntakeState {

  IntakeLoaded({
    required this.leads,
    this.assignmentOptions = const [],
    this.activeStatus,
    this.activeSearch,
  });
  final List<IntakeForm> leads;
  final List<IntakeAssignmentOption> assignmentOptions;
  final String? activeStatus;
  final String? activeSearch;

  IntakeLoaded copyWith({
    List<IntakeForm>? leads,
    List<IntakeAssignmentOption>? assignmentOptions,
    String? activeStatus,
    String? activeSearch,
  }) =>
      IntakeLoaded(
        leads: leads ?? this.leads,
        assignmentOptions: assignmentOptions ?? this.assignmentOptions,
        activeStatus: activeStatus ?? this.activeStatus,
        activeSearch: activeSearch ?? this.activeSearch,
      );
}

class IntakeActionSuccess extends IntakeState {
  IntakeActionSuccess(this.message);
  final String message;
}

class IntakeError extends IntakeState {
  IntakeError(this.message);
  final String message;
}
