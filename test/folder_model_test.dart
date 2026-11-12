import 'package:flutter_test/flutter_test.dart';
import 'package:notefolder/core/network/weather_snapshot.dart';
import 'package:notefolder/data/models/folder_model.dart';
import 'package:notefolder/data/models/note_model.dart';

void main() {
  test('folder persists its identity, name, and creation time', () {
    final createdAt = DateTime.utc(2026, 10, 13, 4, 5);
    final folder = FolderModel(
      id: 'folder-1',
      name: 'Work',
      createdAt: createdAt,
    );

    expect(FolderModel.fromJson(folder.toJson()), folder);
  });

  test('note persists its optional folder relationship', () {
    final now = DateTime.utc(2026, 10, 13);
    final note = NoteModel(
      id: 'note-1',
      title: 'Note',
      content: 'Body',
      createdAt: now,
      updatedAt: now,
      isLocked: false,
      folderId: 'folder-1',
    );

    expect(NoteModel.fromJson(note.toJson()).folderId, 'folder-1');
    expect(note.toEntity().folderId, 'folder-1');
  });

  test('note persists optional map coordinates', () {
    final now = DateTime.utc(2026, 10, 13);
    final note = NoteModel(
      id: 'note-2',
      title: 'Place',
      content: 'A note at this location',
      createdAt: now,
      updatedAt: now,
      isLocked: false,
      latitude: -6.2088,
      longitude: 106.8456,
    );

    final restored = NoteModel.fromJson(note.toJson());

    expect(restored.latitude, -6.2088);
    expect(restored.longitude, 106.8456);
    expect(restored.toEntity().latitude, -6.2088);
  });

  test('note persists photos attached to its content', () {
    final now = DateTime.utc(2026, 10, 13);
    final note = NoteModel(
      id: 'note-3',
      title: 'Photos',
      content: 'A note with photos',
      contentImages: const ['/photos/one.jpg', '/photos/two.jpg'],
      createdAt: now,
      updatedAt: now,
      isLocked: false,
    );

    expect(NoteModel.fromJson(note.toJson()).contentImages, [
      '/photos/one.jpg',
      '/photos/two.jpg',
    ]);
  });

  test('note persists weather chips attached to its content', () {
    final now = DateTime.utc(2026, 10, 13);
    const weather = 'Clear · 25°C';
    final note = NoteModel(
      id: 'note-4',
      title: 'Weather',
      content: 'A note with a weather chip',
      contentWeather: const [weather],
      createdAt: now,
      updatedAt: now,
      isLocked: false,
    );

    expect(NoteModel.fromJson(note.toJson()).contentWeather, [weather]);
    expect(note.toEntity().contentWeather, [weather]);
  });

  test('note persists alignment for each content block', () {
    final now = DateTime.utc(2026, 10, 13);
    final note = NoteModel(
      id: 'note-5',
      title: 'Aligned',
      content: 'Centered content',
      contentBlockAlignments: const ['left', 'center'],
      createdAt: now,
      updatedAt: now,
      isLocked: false,
    );

    expect(NoteModel.fromJson(note.toJson()).contentBlockAlignments, [
      'left',
      'center',
    ]);
    expect(note.toEntity().contentBlockAlignments, ['left', 'center']);
  });

  test('legacy note alignment carries over to every content block', () {
    final now = DateTime.utc(2026, 10, 13);
    final note = NoteModel(
      id: 'note-6',
      title: 'Legacy alignment',
      content: 'First paragraph\nSecond paragraph',
      createdAt: now,
      updatedAt: now,
      isLocked: false,
    );
    final json = note.toJson()
      ..remove('content_block_alignments')
      ..['content_alignment'] = 'right';

    expect(NoteModel.fromJson(json).contentBlockAlignments, ['right', 'right']);
  });

  test('weather snapshot keeps only the condition and temperature', () {
    expect(
      weatherNoteEntry({
        'current': {
          'time': '2026-10-22T09:00',
          'temperature_2m': 28.4,
          'apparent_temperature': 31.2,
          'relative_humidity_2m': 70,
          'weather_code': 1,
          'wind_speed_10m': 8.8,
        },
        'daily': {
          'temperature_2m_max': [30.0],
          'temperature_2m_min': [24.0],
        },
      }),
      'Partly cloudy · 28°C',
    );
  });
}
