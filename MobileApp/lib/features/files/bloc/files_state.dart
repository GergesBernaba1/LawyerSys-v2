import '../models/file_model.dart';

abstract class FilesState {}

class FilesInitial extends FilesState {}

class FilesLoading extends FilesState {}

class FilesLoaded extends FilesState {
  final List<FileModel> files;
  FilesLoaded(this.files);
}

class FilesError extends FilesState {
  final String message;
  FilesError(this.message);
}

class FileOperationSuccess extends FilesState {
  final String message;
  FileOperationSuccess(this.message);
}
