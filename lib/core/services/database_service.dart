import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

class DatabaseService {
  static Database? _database;
  final _updateController = StreamController<String>.broadcast();

  Stream<String> get onTableUpdated => _updateController.stream;

  void notifyTableUpdated(String table) {
    _updateController.add(table);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('campusly.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users Table
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        lastUpdated INTEGER NOT NULL
      )
    ''');

    // Chats Table
    await db.execute('''
      CREATE TABLE chats(
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        participants TEXT NOT NULL DEFAULT '',
        lastUpdated INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_chats_participants ON chats(participants)
    ''');

    // Messages Table
    await db.execute('''
      CREATE TABLE messages(
        id TEXT PRIMARY KEY,
        chatId TEXT NOT NULL,
        data TEXT NOT NULL,
        status TEXT NOT NULL, -- pending, sent, delivered, read
        timestamp INTEGER NOT NULL,
        FOREIGN KEY(chatId) REFERENCES chats(id) ON DELETE CASCADE
      )
    ''');

    // Index for messages to quickly fetch by chatId
    await db.execute('''
      CREATE INDEX idx_messages_chatId ON messages(chatId)
    ''');

    // Sync Queue Table
    await db.execute('''
      CREATE TABLE sync_queue(
        id TEXT PRIMARY KEY,
        action TEXT NOT NULL, -- create_message, update_profile, etc
        payload TEXT NOT NULL, -- JSON payload of the action
        status TEXT NOT NULL, -- pending, failed
        createdAt INTEGER NOT NULL,
        retryCount INTEGER DEFAULT 0
      )
    ''');

    // Offline Academic Data
    await db.execute('''
      CREATE TABLE cache(
        key TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        lastUpdated INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE chats ADD COLUMN participants TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_chats_participants ON chats(participants)",
      );
    }
  }
}
