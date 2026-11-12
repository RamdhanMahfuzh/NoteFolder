import 'package:notefolder/domain/entities/note_entity.dart';
import 'package:notefolder/domain/repositories/note_repository.dart';

class GetNotesById {
  final NoteRepository repository;

  GetNotesById(this.repository);

  Future<NoteEntity> call(String id) async {
    return await repository.getNote(id);
  }
}