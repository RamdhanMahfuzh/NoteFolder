import 'package:notefolder/data/models/folder_model.dart';

abstract class FolderLocalDataSource {
  Future<List<FolderModel>> getFolders();
  Future<void> addFolder(FolderModel folder);
  Future<void> updateFolder(FolderModel folder);
  Future<void> deleteFolder(String id);
}
