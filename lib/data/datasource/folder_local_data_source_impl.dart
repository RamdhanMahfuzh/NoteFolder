import 'package:notefolder/data/database/app_database.dart';
import 'package:notefolder/data/datasource/folder_local_data_source.dart';
import 'package:notefolder/data/models/folder_model.dart';

class FolderLocalDataSourceImpl implements FolderLocalDataSource {
  FolderLocalDataSourceImpl({required this.database});

  final AppDatabase database;

  @override
  Future<List<FolderModel>> getFolders() async {
    final db = await database.database;
    final rows = await db.query(AppDatabase.foldersTable, orderBy: 'name');
    return rows.map(FolderModel.fromJson).toList();
  }

  @override
  Future<void> addFolder(FolderModel folder) async {
    final db = await database.database;
    await db.insert(AppDatabase.foldersTable, folder.toJson());
  }

  @override
  Future<void> updateFolder(FolderModel folder) async {
    final db = await database.database;
    final count = await db.update(
      AppDatabase.foldersTable,
      folder.toJson(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
    if (count == 0) throw Exception('Folder not found');
  }

  @override
  Future<void> deleteFolder(String id) async {
    final db = await database.database;
    await db.transaction((txn) async {
      await txn.update(
        AppDatabase.notesTable,
        {'folder_id': null},
        where: 'folder_id = ?',
        whereArgs: [id],
      );
      final count = await txn.delete(
        AppDatabase.foldersTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) throw Exception('Folder not found');
    });
  }
}
