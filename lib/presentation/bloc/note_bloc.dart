import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notefolder/core/notifications/local_reminder_service.dart';
import 'package:notefolder/domain/entities/note_entity.dart';
import 'package:notefolder/domain/usecase/add_note.dart';
import 'package:notefolder/domain/usecase/delete_note.dart';
import 'package:notefolder/domain/usecase/get_all_notes.dart';
import 'package:notefolder/domain/usecase/get_notes_by_id.dart';
import 'package:notefolder/domain/usecase/update_note.dart';
import 'note_event.dart';
import 'note_state.dart';

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final AddNote addNote;
  final GetAllNotes getAllNotes;
  final GetNotesById getNoteById;
  final UpdateNote updateNote;
  final DeleteNote deleteNote;
  final LocalReminderService reminderService;

  NoteBloc({
    required this.addNote,
    required this.getAllNotes,
    required this.getNoteById,
    required this.updateNote,
    required this.deleteNote,
    required this.reminderService,
  }) : super(const NoteInitial()) {
    on<LoadNotes>(_onLoadNotes);
    on<GetNoteById>(_onGetNoteById);
    on<AddNoteEvent>(_onAddNote);
    on<UpdateNoteEvent>(_onUpdateNote);
    on<DeleteNoteEvent>(_onDeleteNote);
  }

  Future<void> _onLoadNotes(LoadNotes event, Emitter<NoteState> emit) async {
    emit(const NoteLoading());
    try {
      final notes = await getAllNotes();
      emit(NotesLoaded(notes));
    } catch (e) {
      emit(NoteError(e.toString()));
    }
  }

  Future<void> _onGetNoteById(
    GetNoteById event,
    Emitter<NoteState> emit,
  ) async {
    emit(const NoteLoading());
    try {
      final note = await getNoteById(event.id);
      emit(NoteDetailLoaded(note));
    } catch (e) {
      emit(NoteError(e.toString()));
    }
  }

  Future<void> _onAddNote(AddNoteEvent event, Emitter<NoteState> emit) async {
    emit(const NoteLoading());
    try {
      await addNote(event.note);
      final reminderError = await _scheduleReminder(event.note);
      emit(
        NoteOperationSuccess(
          reminderError == null
              ? 'Note added'
              : 'Note added, but its reminder could not be scheduled: $reminderError',
        ),
      );
      add(const LoadNotes());
    } catch (e) {
      emit(NoteError(e.toString()));
    }
  }

  Future<void> _onUpdateNote(
    UpdateNoteEvent event,
    Emitter<NoteState> emit,
  ) async {
    emit(const NoteLoading());
    try {
      await updateNote(event.note);
      final reminderError = await _scheduleReminder(event.note);
      emit(
        NoteOperationSuccess(
          reminderError == null
              ? 'Note updated'
              : 'Note updated, but its reminder could not be scheduled: $reminderError',
          note: event.note,
        ),
      );
      add(const LoadNotes());
    } catch (e) {
      emit(NoteError(e.toString()));
    }
  }

  Future<void> _onDeleteNote(
    DeleteNoteEvent event,
    Emitter<NoteState> emit,
  ) async {
    emit(const NoteLoading());
    try {
      await deleteNote(event.id);
      try {
        await reminderService.cancelDeadline(event.id);
        emit(const NoteOperationSuccess('Note deleted'));
      } catch (e) {
        emit(
          NoteOperationSuccess(
            'Note deleted, but its reminder could not be canceled: $e',
          ),
        );
      }
      add(const LoadNotes());
    } catch (e) {
      emit(NoteError(e.toString()));
    }
  }

  Future<String?> _scheduleReminder(NoteEntity note) async {
    try {
      if (note.deadline == null) {
        await reminderService.cancelDeadline(note.id);
        return null;
      }
      final scheduled = await reminderService.scheduleDeadline(note);
      return scheduled
          ? null
          : 'Notification permission was denied or reminders are unsupported on this device.';
    } catch (e) {
      return e.toString();
    }
  }
}
