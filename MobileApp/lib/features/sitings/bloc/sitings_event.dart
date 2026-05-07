abstract class SitingsEvent {}

class LoadSitings extends SitingsEvent {
  LoadSitings({this.search});
  final String? search;
}

class RefreshSitings extends SitingsEvent {}

class CreateSiting extends SitingsEvent {
  CreateSiting(this.data);
  final Map<String, dynamic> data;
}

class UpdateSiting extends SitingsEvent {
  UpdateSiting(this.id, this.data);
  final int id;
  final Map<String, dynamic> data;
}

class DeleteSiting extends SitingsEvent {
  DeleteSiting(this.id);
  final int id;
}
