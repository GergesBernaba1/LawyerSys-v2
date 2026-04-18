abstract class FilesEvent {}

class LoadFiles extends FilesEvent {
  final String? search;
  LoadFiles({this.search});
}

class RefreshFiles extends FilesEvent {}

class SearchFiles extends FilesEvent {
  final String query;
  SearchFiles(this.query);
}

class CreateFile extends FilesEvent {
  final Map<String, dynamic> data;
  CreateFile(this.data);
}

class UpdateFile extends FilesEvent {
  final String id;
  final Map<String, dynamic> data;
  UpdateFile(this.id, this.data);
}

class DeleteFile extends FilesEvent {
  final String id;
  DeleteFile(this.id);
}
