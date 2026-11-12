import 'package:notefolder/domain/entities/folder_entity.dart';

abstract class FolderRepository {
  Future<List<FolderEntity>> getFolders();
  Future<void> addFolder(FolderEntity folder);
  Future<void> updateFolder(FolderEntity folder);
  Future<void> deleteFolder(String id);
}
