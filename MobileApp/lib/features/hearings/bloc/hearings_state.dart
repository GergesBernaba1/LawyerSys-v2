import 'package:qadaya_lawyersys/features/hearings/models/hearing.dart';

abstract class HearingsState {}

class HearingsInitial extends HearingsState {}

class HearingsLoading extends HearingsState {}

class HearingsLoaded extends HearingsState {
  HearingsLoaded(this.hearings);
  final List<Hearing> hearings;
}

class HearingDetailLoaded extends HearingsState {
  HearingDetailLoaded(this.hearing);
  final Hearing hearing;
}

class HearingsError extends HearingsState {
  HearingsError(this.message);
  final String message;
}

class HearingOperationSuccess extends HearingsState {
  HearingOperationSuccess(this.message);
  final String message;
}
