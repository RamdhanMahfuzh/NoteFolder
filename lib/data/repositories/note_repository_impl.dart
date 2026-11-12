import 'package:notefolder/data/datasource/note_local_data_source.dart';
import 'package:notefolder/data/models/note_model.dart';
import 'package:notefolder/domain/entities/note_entity.dart';
import 'package:notefolder/domain/repositories/note_repository.dart';

class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDataSource localDataSource;

  NoteRepositoryImpl({required this.localDataSource});

  @override
  Future<void> addNote(NoteEntity note) async {
    final model = NoteModel(
      id: note.id,
      banner: note.banner,
      title: note.title,
      content: note.content,
      contentBlockAlignments: note.contentBlockAlignments,
      contentImages: note.contentImages,
      contentWeather: note.contentWeather,
      deadline: note.deadline,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      isLocked: note.isLocked,
      pin: note.pin,
      folderId: note.folderId,
      latitude: note.latitude,
      longitude: note.longitude,
    );

    await localDataSource.addNote(model);
  }

  @override
  Future<List<NoteEntity>> getAllNotes() async {
    final models = await localDataSource.getAllNotes();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<NoteEntity> getNote(String id) async {
    return await localDataSource.getNote(id);
  }

  @override
  Future<void> updateNote(NoteEntity note) async {
    final model = NoteModel(
      id: note.id,
      banner: note.banner,
      title: note.title,
      content: note.content,
      contentBlockAlignments: note.contentBlockAlignments,
      contentImages: note.contentImages,
      contentWeather: note.contentWeather,
      deadline: note.deadline,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      isLocked: note.isLocked,
      pin: note.pin,
      folderId: note.folderId,
      latitude: note.latitude,
      longitude: note.longitude,
    );

    await localDataSource.updateNote(model);
  }

  @override
  Future<void> deleteNote(String id) async {
    await localDataSource.deleteNote(id);
  }
}
