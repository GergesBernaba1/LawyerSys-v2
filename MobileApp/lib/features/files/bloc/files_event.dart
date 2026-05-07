abstract class FilesEvent {}

class LoadFiles extends FilesEvent {
  LoadFiles({this.search});
  final String? search;
}

class RefreshFiles extends FilesEvent {}

class SearchFiles extends FilesEvent {
  SearchFiles(this.query);
  final String query;
}

class CreateFile extends FilesEvent {
  CreateFile(this.data);
  final Map<String, dynamic> data;
}

class UpdateFile extends FilesEvent {
  UpdateFile(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
}

class DeleteFile extends FilesEvent {
  DeleteFile(this.id);
  final String id;
}
