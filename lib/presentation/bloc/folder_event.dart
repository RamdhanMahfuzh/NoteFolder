import 'package:equatable/equatable.dart';
import 'package:notefolder/domain/entities/folder_entity.dart';

abstract class FolderEvent extends Equatable {
  const FolderEvent();

  @override
  List<Object?> get props => [];
}

class LoadFolders extends FolderEvent {
  const LoadFolders();
}

class AddFolderEvent extends FolderEvent {
  const AddFolderEvent(this.folder);
  final FolderEntity folder;

  @override
  List<Object?> get props => [folder];
}

class UpdateFolderEvent extends FolderEvent {
  const UpdateFolderEvent(this.folder);
  final FolderEntity folder;

  @override
  List<Object?> get props => [folder];
}

class DeleteFolderEvent extends FolderEvent {
  const DeleteFolderEvent(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}
