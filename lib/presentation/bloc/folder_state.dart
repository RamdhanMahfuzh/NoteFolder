import 'package:equatable/equatable.dart';
import 'package:notefolder/domain/entities/folder_entity.dart';

abstract class FolderState extends Equatable {
  const FolderState();

  @override
  List<Object?> get props => [];
}

class FolderInitial extends FolderState {
  const FolderInitial();
}

class FolderLoading extends FolderState {
  const FolderLoading();
}

class FoldersLoaded extends FolderState {
  const FoldersLoaded(this.folders, {this.message});
  final List<FolderEntity> folders;
  final String? message;

  @override
  List<Object?> get props => [folders, message];
}

class FolderError extends FolderState {
  const FolderError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
