import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notefolder/core/backup/backup_exporter.dart';

void main() {
  test('backup contains notes, folders, and embedded image files', () async {
    final directory = await Directory.systemTemp.createTemp('noteapp-backup-');
    addTearDown(() => directory.delete(recursive: true));
    final image = File('${directory.path}${Platform.pathSeparator}photo.jpg');
    await image.writeAsBytes([1, 2, 3]);

    final backup =
        jsonDecode(
              await createBackupJson(
                notes: [
                  {
                    'id': 'note-1',
                    'banner': image.path,
                    'content_images': jsonEncode([image.path]),
                  },
                ],
                folders: [
                  {'id': 'folder-1', 'name': 'Work'},
                ],
              ),
            )
            as Map<String, dynamic>;

    expect(backup['format_version'], 1);
    expect((backup['notes'] as List).single['id'], 'note-1');
    expect((backup['folders'] as List).single['name'], 'Work');
    expect(
      (backup['assets_base64'] as Map<String, dynamic>)[image.path],
      base64Encode([1, 2, 3]),
    );
  });
}
