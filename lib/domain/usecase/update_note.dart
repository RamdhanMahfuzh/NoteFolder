import 'package:notefolder/domain/entities/note_entity.dart';
import 'package:notefolder/domain/repositories/note_repository.dart';

class UpdateNote {
  final NoteRepository repository;

  UpdateNote(this.repository);

  Future<void> call(NoteEntity note) async {
    await repository.updateNote(note);
  }
}
