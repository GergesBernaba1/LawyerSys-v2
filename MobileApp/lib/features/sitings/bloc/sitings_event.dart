abstract class SitingsEvent {}

class LoadSitings extends SitingsEvent {
  final String? search;
  LoadSitings({this.search});
}

class RefreshSitings extends SitingsEvent {}

class CreateSiting extends SitingsEvent {
  final Map<String, dynamic> data;
  CreateSiting(this.data);
}

class UpdateSiting extends SitingsEvent {
  final int id;
  final Map<String, dynamic> data;
  UpdateSiting(this.id, this.data);
}

class DeleteSiting extends SitingsEvent {
  final int id;
  DeleteSiting(this.id);
}
