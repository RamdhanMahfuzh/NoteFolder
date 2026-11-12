import 'package:notefolder/domain/entities/note_entity.dart';

abstract class NoteRepository {
  Future<void> addNote(NoteEntity note);
  Future<List<NoteEntity>> getAllNotes();
  Future<NoteEntity> getNote(String id);
  Future<void> updateNote(NoteEntity note);
  Future<void> deleteNote(String id);
}
