import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const String _databaseName = 'notepad.db';
  static const int _databaseVersion = 8;

  static const String notesTable = 'notes';
  static const String foldersTable = 'folders';

  Future<Database> get database async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $notesTable (
        id TEXT PRIMARY KEY,
        banner TEXT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        content_alignment TEXT NOT NULL DEFAULT 'left',
        content_block_alignments TEXT,
        content_images TEXT,
        content_weather TEXT,
        deadline TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_locked INTEGER NOT NULL DEFAULT 0,
        pin TEXT,
        folder_id TEXT,
        latitude REAL,
        longitude REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE $foldersTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _addColumnIfMissing(db, 'is_locked', 'INTEGER NOT NULL DEFAULT 0');
      await _addColumnIfMissing(db, 'pin', 'TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $foldersTable (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      await _addColumnIfMissing(db, 'folder_id', 'TEXT');
    }
    if (oldVersion < 4) {
      await _addColumnIfMissing(db, 'latitude', 'REAL');
      await _addColumnIfMissing(db, 'longitude', 'REAL');
    }
    if (oldVersion < 5) {
      await _addColumnIfMissing(db, 'content_images', 'TEXT');
    }
    if (oldVersion < 6) {
      await _addColumnIfMissing(db, 'content_weather', 'TEXT');
    }
    if (oldVersion < 7) {
      await _addColumnIfMissing(
        db,
        'content_alignment',
        "TEXT NOT NULL DEFAULT 'left'",
      );
    }
    if (oldVersion < 8) {
      await _addColumnIfMissing(db, 'content_block_alignments', 'TEXT');
    }
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($notesTable)');
    if (columns.any((row) => row['name'] == column)) return;
    await db.execute('ALTER TABLE $notesTable ADD COLUMN $column $definition');
  }
}
