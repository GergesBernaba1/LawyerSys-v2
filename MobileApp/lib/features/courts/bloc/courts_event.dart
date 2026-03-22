import '../models/court.dart';

abstract class CourtsEvent {}

class LoadCourts extends CourtsEvent {}
class RefreshCourts extends CourtsEvent {}

class SearchCourts extends CourtsEvent {
  final String query;
  SearchCourts(this.query);
}

class SelectCourt extends CourtsEvent {
  final String courtId;
  SelectCourt(this.courtId);
}

class CreateCourt extends CourtsEvent {
  final CourtModel court;
  CreateCourt(this.court);
}

class UpdateCourt extends CourtsEvent {
  final CourtModel court;
  UpdateCourt(this.court);
}

class DeleteCourt extends CourtsEvent {
  final String courtId;
  DeleteCourt(this.courtId);
}
