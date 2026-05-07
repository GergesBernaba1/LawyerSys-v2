import 'package:qadaya_lawyersys/features/courts/models/court.dart';

abstract class CourtsState {}

class CourtsInitial extends CourtsState {}
class CourtsLoading extends CourtsState {}

class CourtsLoaded extends CourtsState {
  CourtsLoaded(this.courts);
  final List<CourtModel> courts;
}

class CourtsError extends CourtsState {
  CourtsError(this.message);
  final String message;
}

class CourtDetailLoaded extends CourtsState {
  CourtDetailLoaded(this.court);
  final CourtModel court;
}

class CourtOperationSuccess extends CourtsState {
  CourtOperationSuccess(this.message);
  final String message;
}
