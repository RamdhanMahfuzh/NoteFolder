import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notefolder/domain/usecase/folder_usecases.dart';
import 'package:notefolder/presentation/bloc/folder_event.dart';
import 'package:notefolder/presentation/bloc/folder_state.dart';

class FolderBloc extends Bloc<FolderEvent, FolderState> {
  FolderBloc({
    required this.getFolders,
    required this.addFolder,
    required this.updateFolder,
    required this.deleteFolder,
  }) : super(const FolderInitial()) {
    on<LoadFolders>(_onLoad);
    on<AddFolderEvent>(_onAdd);
    on<UpdateFolderEvent>(_onUpdate);
    on<DeleteFolderEvent>(_onDelete);
  }

  final GetFolders getFolders;
  final AddFolder addFolder;
  final UpdateFolder updateFolder;
  final DeleteFolder deleteFolder;

  Future<void> _onLoad(LoadFolders event, Emitter<FolderState> emit) async {
    emit(const FolderLoading());
    try {
      emit(FoldersLoaded(await getFolders()));
    } catch (e) {
      emit(FolderError(e.toString()));
    }
  }

  Future<void> _onAdd(AddFolderEvent event, Emitter<FolderState> emit) async {
    try {
      await addFolder(event.folder);
      emit(FoldersLoaded(await getFolders(), message: 'Folder added'));
    } catch (e) {
      emit(FolderError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateFolderEvent event,
    Emitter<FolderState> emit,
  ) async {
    try {
      await updateFolder(event.folder);
      emit(FoldersLoaded(await getFolders(), message: 'Folder updated'));
    } catch (e) {
      emit(FolderError(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteFolderEvent event,
    Emitter<FolderState> emit,
  ) async {
    try {
      await deleteFolder(event.id);
      emit(
        FoldersLoaded(
          await getFolders(),
          message: 'Folder deleted; notes are unfiled',
        ),
      );
    } catch (e) {
      emit(FolderError(e.toString()));
    }
  }
}
