import 'package:equatable/equatable.dart';
import 'package:notefolder/domain/entities/note_entity.dart';

abstract class NoteState extends Equatable {
  const NoteState();
  @override
  List<Object?> get props => [];
}

class NoteInitial extends NoteState {
  const NoteInitial();
}

class NoteLoading extends NoteState {
  const NoteLoading();
}

class NotesLoaded extends NoteState {
  final List<NoteEntity> notes;
  const NotesLoaded(this.notes);
  @override
  List<Object?> get props => [notes];
}

class NoteDetailLoaded extends NoteState {
  final NoteEntity note;
  const NoteDetailLoaded(this.note);
  @override
  List<Object?> get props => [note];
}

class NoteOperationSuccess extends NoteState {
  final String message;
  final NoteEntity? note;
  const NoteOperationSuccess(this.message, {this.note});
  @override
  List<Object?> get props => [message, note];
}

class NoteError extends NoteState {
  final String message;
  const NoteError(this.message);
  @override
  List<Object?> get props => [message];
}
