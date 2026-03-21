import '../models/contender.dart';

abstract class ContendersEvent {}

class LoadContenders extends ContendersEvent {}
class RefreshContenders extends ContendersEvent {}

class SearchContenders extends ContendersEvent {
  final String query;
  SearchContenders(this.query);
}

class SelectContender extends ContendersEvent {
  final String contenderId;
  SelectContender(this.contenderId);
}

class CreateContender extends ContendersEvent {
  final ContenderModel contender;
  CreateContender(this.contender);
}

class UpdateContender extends ContendersEvent {
  final ContenderModel contender;
  UpdateContender(this.contender);
}

class DeleteContender extends ContendersEvent {
  final String contenderId;
  DeleteContender(this.contenderId);
}
