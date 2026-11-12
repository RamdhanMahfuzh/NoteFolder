import 'package:notefolder/domain/entities/folder_entity.dart';
import 'package:notefolder/domain/repositories/folder_repository.dart';

class GetFolders {
  const GetFolders(this.repository);
  final FolderRepository repository;
  Future<List<FolderEntity>> call() => repository.getFolders();
}

class AddFolder {
  const AddFolder(this.repository);
  final FolderRepository repository;
  Future<void> call(FolderEntity folder) => repository.addFolder(folder);
}

class UpdateFolder {
  const UpdateFolder(this.repository);
  final FolderRepository repository;
  Future<void> call(FolderEntity folder) => repository.updateFolder(folder);
}

class DeleteFolder {
  const DeleteFolder(this.repository);
  final FolderRepository repository;
  Future<void> call(String id) => repository.deleteFolder(id);
}
