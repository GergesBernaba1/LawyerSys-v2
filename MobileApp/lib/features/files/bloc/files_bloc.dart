import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/files/bloc/files_event.dart';
import 'package:qadaya_lawyersys/features/files/bloc/files_state.dart';
import 'package:qadaya_lawyersys/features/files/repositories/files_repository.dart';

class FilesBloc extends Bloc<FilesEvent, FilesState> {

  FilesBloc({required this.filesRepository}) : super(FilesInitial()) {
    on<LoadFiles>(_onLoadFiles);
    on<RefreshFiles>(_onRefreshFiles);
    on<SearchFiles>(_onSearchFiles);
    on<CreateFile>(_onCreateFile);
    on<UpdateFile>(_onUpdateFile);
    on<DeleteFile>(_onDeleteFile);
  }
  final FilesRepository filesRepository;

  Future<void> _onLoadFiles(
    LoadFiles event,
    Emitter<FilesState> emit,
  ) async {
    emit(FilesLoading());
    try {
      final files = await filesRepository.getFiles(search: event.search);
      emit(FilesLoaded(files));
    } catch (e) {
      emit(FilesError(e.toString()));
    }
  }

  Future<void> _onRefreshFiles(
    RefreshFiles event,
    Emitter<FilesState> emit,
  ) async {
    try {
      final files = await filesRepository.getFiles();
      emit(FilesLoaded(files));
    } catch (e) {
      emit(FilesError(e.toString()));
    }
  }

  Future<void> _onSearchFiles(
    SearchFiles event,
    Emitter<FilesState> emit,
  ) async {
    emit(FilesLoading());
    try {
      final files = await filesRepository.getFiles(search: event.query);
      emit(FilesLoaded(files));
    } catch (e) {
      emit(FilesError(e.toString()));
    }
  }

  Future<void> _onCreateFile(
    CreateFile event,
    Emitter<FilesState> emit,
  ) async {
    emit(FilesLoading());
    try {
      await filesRepository.createFile(event.data);
      emit(FileOperationSuccess('File created successfully'));
      final files = await filesRepository.getFiles();
      emit(FilesLoaded(files));
    } catch (e) {
      emit(FilesError(e.toString()));
    }
  }

  Future<void> _onUpdateFile(
    UpdateFile event,
    Emitter<FilesState> emit,
  ) async {
    emit(FilesLoading());
    try {
      await filesRepository.updateFile(event.id, event.data);
      emit(FileOperationSuccess('File updated successfully'));
      final files = await filesRepository.getFiles();
      emit(FilesLoaded(files));
    } catch (e) {
      emit(FilesError(e.toString()));
    }
  }

  Future<void> _onDeleteFile(
    DeleteFile event,
    Emitter<FilesState> emit,
  ) async {
    emit(FilesLoading());
    try {
      await filesRepository.deleteFile(event.id);
      emit(FileOperationSuccess('File deleted successfully'));
      final files = await filesRepository.getFiles();
      emit(FilesLoaded(files));
    } catch (e) {
      emit(FilesError(e.toString()));
    }
  }
}
