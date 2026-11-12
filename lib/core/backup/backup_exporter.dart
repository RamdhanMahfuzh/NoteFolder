import 'dart:convert';
import 'dart:io';

Future<String> createBackupJson({
  required List<Map<String, dynamic>> notes,
  required List<Map<String, dynamic>> folders,
}) async {
  final assets = <String, String>{};

  Future<void> includeAsset(String? path) async {
    if (path == null || path.isEmpty || assets.containsKey(path)) return;
    assets[path] = base64Encode(await File(path).readAsBytes());
  }

  for (final note in notes) {
    await includeAsset(note['banner'] as String?);
    final imagePaths = note['content_images'] as String?;
    if (imagePaths != null) {
      for (final path in jsonDecode(imagePaths) as List) {
        await includeAsset(path as String);
      }
    }
  }

  return jsonEncode({
    'format_version': 1,
    'exported_at': DateTime.now().toIso8601String(),
    'notes': notes,
    'folders': folders,
    'assets_base64': assets,
  });
}
