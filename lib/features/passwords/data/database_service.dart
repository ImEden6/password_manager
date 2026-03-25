import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models/password_entry.dart';
import 'encryption_service.dart';

/// SQLite database service for CRUD operations on password entries.
///
/// All sensitive fields are encrypted before storage and decrypted
/// on retrieval. [createdAt] is set once on insert and never modified.
class DatabaseService {
  static const _dbName = 'password_manager.db';
  static const _dbVersion = 1;
  static const _tableName = 'passwords';

  final EncryptionService _encryptionService;
  Database? _database;

  DatabaseService(this._encryptionService);

  /// Get or create the database instance.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            siteName TEXT NOT NULL,
            siteUrl TEXT,
            username TEXT NOT NULL,
            password TEXT NOT NULL,
            pin TEXT,
            notes TEXT,
            category TEXT NOT NULL DEFAULT 'General',
            isFavorite INTEGER NOT NULL DEFAULT 0,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            lastAccessedAt INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  /// Insert a new entry. Sets createdAt, updatedAt, lastAccessedAt to now.
  Future<int> insertEntry(PasswordEntry entry) async {
    final db = await database;
    final now = DateTime.now();

    // Encrypt sensitive fields before storing.
    final encryptedEntry = PasswordEntry(
      siteName: entry.siteName,
      siteUrl: entry.siteUrl,
      username: entry.username,
      password: _encryptionService.encryptText(entry.password),
      pin: _encryptionService.encryptField(entry.pin),
      notes: _encryptionService.encryptField(entry.notes),
      category: entry.category,
      isFavorite: entry.isFavorite,
      createdAt: now,
      updatedAt: now,
      lastAccessedAt: now,
    );

    return db.insert(_tableName, encryptedEntry.toMap());
  }

  /// Update an existing entry. Updates [updatedAt] but NEVER [createdAt].
  Future<int> updateEntry(PasswordEntry entry) async {
    final db = await database;
    final now = DateTime.now();

    final encryptedEntry = PasswordEntry(
      id: entry.id,
      siteName: entry.siteName,
      siteUrl: entry.siteUrl,
      username: entry.username,
      password: _encryptionService.encryptText(entry.password),
      pin: _encryptionService.encryptField(entry.pin),
      notes: _encryptionService.encryptField(entry.notes),
      category: entry.category,
      isFavorite: entry.isFavorite,
      createdAt: entry.createdAt, // Immutable
      updatedAt: now, // Updated
      lastAccessedAt: entry.lastAccessedAt, // Unchanged on edit
    );

    return db.update(
      _tableName,
      encryptedEntry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// Delete an entry by ID.
  Future<int> deleteEntry(int id) async {
    final db = await database;
    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Get all entries, decrypted. Sorted: favorites first, then by lastAccessedAt desc.
  Future<List<PasswordEntry>> getAllEntries() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      orderBy: 'isFavorite DESC, lastAccessedAt DESC',
    );
    return maps.map((map) => _decryptEntry(PasswordEntry.fromMap(map))).toList();
  }

  /// Search entries across site name, username, AND URL.
  Future<List<PasswordEntry>> searchEntries(String query) async {
    final db = await database;
    final wildcard = '%$query%';
    final maps = await db.query(
      _tableName,
      where: 'siteName LIKE ? OR username LIKE ? OR siteUrl LIKE ?',
      whereArgs: [wildcard, wildcard, wildcard],
      orderBy: 'isFavorite DESC, lastAccessedAt DESC',
    );
    return maps.map((map) => _decryptEntry(PasswordEntry.fromMap(map))).toList();
  }

  /// Update lastAccessedAt when an entry is viewed or copied.
  Future<void> touchEntry(int id) async {
    final db = await database;
    await db.update(
      _tableName,
      {'lastAccessedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Toggle the isFavorite flag.
  Future<void> toggleFavorite(int id, bool currentValue) async {
    final db = await database;
    await db.update(
      _tableName,
      {'isFavorite': currentValue ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Decrypt all sensitive fields of an entry.
  PasswordEntry _decryptEntry(PasswordEntry entry) {
    return entry.copyWith(
      password: _encryptionService.decryptText(entry.password),
      pin: _encryptionService.decryptField(entry.pin),
      notes: _encryptionService.decryptField(entry.notes),
    );
  }

  /// Get all entries as raw encrypted maps (for backup export).
  Future<List<Map<String, dynamic>>> getAllEntriesRaw() async {
    final db = await database;
    return db.query(_tableName, orderBy: 'id ASC');
  }

  /// Insert a raw map directly (for backup import).
  Future<void> insertRaw(Map<String, dynamic> map) async {
    final db = await database;
    // Remove id so auto-increment assigns a new one.
    final cleaned = Map<String, dynamic>.from(map)..remove('id');
    await db.insert(_tableName, cleaned);
  }
}
