import '../models/court.dart';

abstract class CourtsState {}

class CourtsInitial extends CourtsState {}
class CourtsLoading extends CourtsState {}

class CourtsLoaded extends CourtsState {
  final List<CourtModel> courts;
  CourtsLoaded(this.courts);
}

class CourtsError extends CourtsState {
  final String message;
  CourtsError(this.message);
}

class CourtDetailLoaded extends CourtsState {
  final CourtModel court;
  CourtDetailLoaded(this.court);
}

class CourtOperationSuccess extends CourtsState {
  final String message;
  CourtOperationSuccess(this.message);
}
