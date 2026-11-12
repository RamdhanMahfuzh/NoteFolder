import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:notefolder/data/database/app_database.dart';
import 'package:notefolder/core/network/dio_client.dart';
import 'package:notefolder/core/network/weather_service.dart';
import 'package:notefolder/core/notifications/local_reminder_service.dart';
import 'package:notefolder/data/datasource/folder_local_data_source.dart';
import 'package:notefolder/data/datasource/folder_local_data_source_impl.dart';
import 'package:notefolder/data/datasource/note_local_data_source.dart';
import 'package:notefolder/data/datasource/note_local_data_source_impl.dart';
import 'package:notefolder/data/repositories/note_repository_impl.dart';
import 'package:notefolder/data/repositories/folder_repository_impl.dart';
import 'package:notefolder/domain/repositories/folder_repository.dart';
import 'package:notefolder/domain/usecase/folder_usecases.dart';
import 'package:notefolder/domain/repositories/note_repository.dart';
import 'package:notefolder/domain/usecase/add_note.dart';
import 'package:notefolder/domain/usecase/delete_note.dart';
import 'package:notefolder/domain/usecase/get_all_notes.dart';
import 'package:notefolder/domain/usecase/get_notes_by_id.dart';
import 'package:notefolder/domain/usecase/update_note.dart';
import 'package:notefolder/presentation/bloc/note_bloc.dart';
import 'package:notefolder/presentation/bloc/folder_bloc.dart';

// This is a service locator for dependency injection
final sl = GetIt.instance;
// appdatabase (sqlite)
Future<void> init() async {
  sl.registerLazySingleton<Dio>(createDioClient);
  sl.registerLazySingleton<WeatherService>(() => WeatherService(sl()));
  sl.registerLazySingleton<LocalReminderService>(LocalReminderService.new);
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
  // data source
  sl.registerLazySingleton<NoteLocalDataSource>(
    () => NoteLocalDataSourceImpl(database: sl()),
  );
  sl.registerLazySingleton<FolderLocalDataSource>(
    () => FolderLocalDataSourceImpl(database: sl()),
  );
  // repository
  sl.registerLazySingleton<NoteRepository>(
    () => NoteRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<FolderRepository>(
    () => FolderRepositoryImpl(localDataSource: sl()),
  );
  // usecase
  sl.registerLazySingleton(() => AddNote(sl()));
  sl.registerLazySingleton(() => GetAllNotes(sl()));
  sl.registerLazySingleton(() => GetNotesById(sl()));
  sl.registerLazySingleton(() => UpdateNote(sl()));
  sl.registerLazySingleton(() => DeleteNote(sl()));
  sl.registerLazySingleton(() => GetFolders(sl()));
  sl.registerLazySingleton(() => AddFolder(sl()));
  sl.registerLazySingleton(() => UpdateFolder(sl()));
  sl.registerLazySingleton(() => DeleteFolder(sl()));
  // bloc
  sl.registerFactory(
    () => NoteBloc(
      addNote: sl(),
      getAllNotes: sl(),
      getNoteById: sl(),
      updateNote: sl(),
      deleteNote: sl(),
      reminderService: sl(),
    ),
  );
  sl.registerFactory(
    () => FolderBloc(
      getFolders: sl(),
      addFolder: sl(),
      updateFolder: sl(),
      deleteFolder: sl(),
    ),
  );
}
