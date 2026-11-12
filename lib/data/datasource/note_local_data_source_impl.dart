import 'package:notefolder/data/database/app_database.dart';
import 'package:notefolder/data/datasource/note_local_data_source.dart';
import 'package:notefolder/data/models/note_model.dart';

class NoteLocalDataSourceImpl implements NoteLocalDataSource {
  // Implementation details for the NoteLocalDataSource

  final AppDatabase database;

  NoteLocalDataSourceImpl({required this.database});

  // ini buat create table di database
  @override
  Future<void> addNote(NoteModel note) async {
    final db = await database.database;
    await db.insert(AppDatabase.notesTable, note.toJson());
  }

  // buat nampilin semua data note yang ada di database
  @override
  Future<List<NoteModel>> getAllNotes() async {
    final db = await database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppDatabase.notesTable,
    );

    return List.generate(maps.length, (i) {
      return NoteModel.fromJson(maps[i]);
    });
  }

  // buat mengambil data note berdasarkan id
  @override
  Future<NoteModel> getNote(String id) async {
    final db = await database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppDatabase.notesTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return NoteModel.fromJson(maps.first);
    } else {
      throw Exception('Note not found');
    }
  }

  // buat update data note berdasarkan id
  @override
  Future<void> updateNote(NoteModel note) async {
    final db = await database.database;
    await db.update(
      AppDatabase.notesTable,
      note.toJson(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // buat delete data note berdasarkan id
  @override
  Future<void> deleteNote(String id) async {
    final db = await database.database;
    await db.delete(AppDatabase.notesTable, where: 'id = ?', whereArgs: [id]);
  }
}
