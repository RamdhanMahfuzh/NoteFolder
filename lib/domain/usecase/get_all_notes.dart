import 'package:notefolder/domain/entities/note_entity.dart';
import 'package:notefolder/domain/repositories/note_repository.dart';

class GetAllNotes {
  final NoteRepository repository;

  GetAllNotes(this.repository);

  Future<List<NoteEntity>> call() async {
    return await repository.getAllNotes();
  }
}
