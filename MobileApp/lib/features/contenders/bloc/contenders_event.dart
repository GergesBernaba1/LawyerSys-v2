import 'package:qadaya_lawyersys/features/contenders/models/contender.dart';

abstract class ContendersEvent {}

class LoadContenders extends ContendersEvent {}
class RefreshContenders extends ContendersEvent {}

class SearchContenders extends ContendersEvent {
  SearchContenders(this.query);
  final String query;
}

class SelectContender extends ContendersEvent {
  SelectContender(this.contenderId);
  final String contenderId;
}

class CreateContender extends ContendersEvent {
  CreateContender(this.contender);
  final ContenderModel contender;
}

class UpdateContender extends ContendersEvent {
  UpdateContender(this.contender);
  final ContenderModel contender;
}

class DeleteContender extends ContendersEvent {
  DeleteContender(this.contenderId);
  final String contenderId;
}
