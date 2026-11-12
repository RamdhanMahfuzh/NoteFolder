import 'package:go_router/go_router.dart';
import 'package:notefolder/core/routes/app_routes.dart';
import 'package:notefolder/presentation/pages/add_note_page.dart';
import 'package:notefolder/presentation/pages/all_notes_page.dart';
import 'package:notefolder/presentation/pages/home_page.dart';
import 'package:notefolder/presentation/pages/note_detail_page.dart';
import 'package:notefolder/presentation/pages/pin_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.addNote,
      name: 'addNote',
      builder: (context, state) => const AddNotePage(),
    ),
    GoRoute(
      path: AppRoutes.allNotes,
      name: 'allNotes',
      builder: (context, state) => const AllNotesPage(),
    ),
    GoRoute(
      path: AppRoutes.noteDetail,
      name: 'noteDetail',
      builder: (context, state) =>
          NoteDetailPage(noteId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: AppRoutes.pin,
      name: 'pin',
      builder: (context, state) => PinPage(noteId: state.pathParameters['id']!),
    ),
  ],
);
