abstract class HearingsEvent {}

class LoadHearings extends HearingsEvent {}

class SearchHearings extends HearingsEvent {
  SearchHearings(this.query);
  final String query;
}

class RefreshHearings extends HearingsEvent {}

class LoadHearingDetail extends HearingsEvent {
  LoadHearingDetail(this.hearingId);
  final String hearingId;
}

class CreateHearing extends HearingsEvent {
  CreateHearing(this.hearing);
  final dynamic hearing;
}

class UpdateHearing extends HearingsEvent {
  UpdateHearing(this.hearing);
  final dynamic hearing;
}

class DeleteHearing extends HearingsEvent {
  DeleteHearing(this.hearingId);
  final String hearingId;
}
