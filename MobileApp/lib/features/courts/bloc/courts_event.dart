import 'package:qadaya_lawyersys/features/courts/models/court.dart';

abstract class CourtsEvent {}

class LoadCourts extends CourtsEvent {}
class RefreshCourts extends CourtsEvent {}

class SearchCourts extends CourtsEvent {
  SearchCourts(this.query);
  final String query;
}

class SelectCourt extends CourtsEvent {
  SelectCourt(this.courtId);
  final String courtId;
}

class CreateCourt extends CourtsEvent {
  CreateCourt(this.court);
  final CourtModel court;
}

class UpdateCourt extends CourtsEvent {
  UpdateCourt(this.court);
  final CourtModel court;
}

class DeleteCourt extends CourtsEvent {
  DeleteCourt(this.courtId);
  final String courtId;
}
