abstract class HearingsEvent {}

class LoadHearings extends HearingsEvent {}

class SearchHearings extends HearingsEvent {
  final String query;
  SearchHearings(this.query);
}

class RefreshHearings extends HearingsEvent {}

class LoadHearingDetail extends HearingsEvent {
  final String hearingId;
  LoadHearingDetail(this.hearingId);
}

class CreateHearing extends HearingsEvent {
  final dynamic hearing;
  CreateHearing(this.hearing);
}

class UpdateHearing extends HearingsEvent {
  final dynamic hearing;
  UpdateHearing(this.hearing);
}

class DeleteHearing extends HearingsEvent {
  final String hearingId;
  DeleteHearing(this.hearingId);
}
