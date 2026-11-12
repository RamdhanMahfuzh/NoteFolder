import 'package:notefolder/domain/repositories/note_repository.dart';

class DeleteNote {
  final NoteRepository repository;

  DeleteNote(this.repository);

  Future<void> call(String id) async {
    await repository.deleteNote(id);
  }
}
