import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notefolder/core/routes/app_route.dart';
import 'package:notefolder/core/notifications/local_reminder_service.dart';
import 'package:notefolder/core/themes/app_themes.dart';
import 'package:notefolder/core/themes/theme_mode_scope.dart';
import 'package:notefolder/injection/injection.dart' as di;
import 'package:notefolder/presentation/bloc/note_bloc.dart';
import 'package:notefolder/presentation/bloc/folder_bloc.dart';
import 'package:notefolder/presentation/bloc/folder_event.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await di.init();
  await di.sl<LocalReminderService>().initialize();
  runApp(const NoteApp());
}

class NoteApp extends StatefulWidget {
  const NoteApp({super.key});

  @override
  State<NoteApp> createState() => _NoteAppState();
}

class _NoteAppState extends State<NoteApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<NoteBloc>()),
        BlocProvider(
          create: (_) => di.sl<FolderBloc>()..add(const LoadFolders()),
        ),
      ],
      child: ThemeModeScope(
        isDarkMode: _isDarkMode,
        toggle: () => setState(() => _isDarkMode = !_isDarkMode),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
