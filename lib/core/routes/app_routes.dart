abstract class AppRoutes {
  static const String home = '/';
  static const String addNote = '/add';
  static const String allNotes = '/notes';
  static const String noteDetail = '/note/:id';
  static String noteDetailPath(String id) => '/note/$id';
  static const String pin = '/pin/:id';
  static String pinPath(String id) => '/pin/$id';
  static const String editNote = '/edit';
}
