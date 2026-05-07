import 'package:qadaya_lawyersys/features/files/models/file_model.dart';

abstract class FilesState {}

class FilesInitial extends FilesState {}

class FilesLoading extends FilesState {}

class FilesLoaded extends FilesState {
  FilesLoaded(this.files);
  final List<FileModel> files;
}

class FilesError extends FilesState {
  FilesError(this.message);
  final String message;
}

class FileOperationSuccess extends FilesState {
  FileOperationSuccess(this.message);
  final String message;
}
