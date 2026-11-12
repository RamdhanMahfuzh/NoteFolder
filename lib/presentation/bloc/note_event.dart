import 'package:equatable/equatable.dart';
import 'package:notefolder/domain/entities/note_entity.dart';

abstract class NoteEvent extends Equatable {
  const NoteEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotes extends NoteEvent {
  const LoadNotes();
}

class GetNoteById extends NoteEvent {
  final String id;
  const GetNoteById(this.id);
  @override
  List<Object?> get props => [id];
}

class AddNoteEvent extends NoteEvent {
  final NoteEntity note;
  const AddNoteEvent(this.note);
  @override
  List<Object?> get props => [note];
}

class UpdateNoteEvent extends NoteEvent {
  final NoteEntity note;
  const UpdateNoteEvent(this.note);
  @override
  List<Object?> get props => [note];
}

class DeleteNoteEvent extends NoteEvent {
  final String id;
  const DeleteNoteEvent(this.id);
  @override
  List<Object?> get props => [id];
}
