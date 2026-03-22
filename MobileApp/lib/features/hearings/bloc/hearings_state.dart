import '../models/hearing.dart';

abstract class HearingsState {}

class HearingsInitial extends HearingsState {}

class HearingsLoading extends HearingsState {}

class HearingsLoaded extends HearingsState {
  final List<Hearing> hearings;
  HearingsLoaded(this.hearings);
}

class HearingDetailLoaded extends HearingsState {
  final Hearing hearing;
  HearingDetailLoaded(this.hearing);
}

class HearingsError extends HearingsState {
  final String message;
  HearingsError(this.message);
}

class HearingOperationSuccess extends HearingsState {
  final String message;
  HearingOperationSuccess(this.message);
}
