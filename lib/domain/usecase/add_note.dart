import 'package:notefolder/domain/entities/note_entity.dart';
import 'package:notefolder/domain/repositories/note_repository.dart';

class AddNote {
  final NoteRepository repository;

  AddNote(this.repository);

  Future<void> call(NoteEntity note) async {
    await repository.addNote(note);
  }
}
