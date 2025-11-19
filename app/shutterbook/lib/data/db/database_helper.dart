// Shutterbook — database_helper.dart
// Provides a small, cross-platform SQLite helper that initializes the
// application schema and exposes a singleton Database instance. Used by the
// table helpers under `data/tables`.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final _databaseName = 'shutterbook.db';
  static final _databaseVersion = 3;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    if (kDebugMode) debugPrint('Opening database at: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Clients (
        client_id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL
      )
      ''');

    await db.execute('''
      CREATE TABLE Quotes (
        quote_id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL, 
        total_price REAL NOT NULL,
        description TEXT NOT NULL,
        created_at DATETIME DEFAULT (strftime('%Y-%m-%d %H:%M', 'now', 'localtime')),
        FOREIGN KEY (client_id) REFERENCES Clients(client_id) ON DELETE CASCADE
      )
      ''');

    await db.execute('''
      CREATE TABLE Bookings (
        booking_id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER NOT NULL,
        client_id INTEGER NOT NULL, 
        booking_date DATE NOT NULL,
        status TEXT DEFAULT 'Scheduled',
        created_at DATETIME DEFAULT (strftime('%Y-%m-%d %H:%M', 'now', 'localtime')),
        FOREIGN KEY (client_id) REFERENCES Clients(client_id) ON DELETE CASCADE,
        FOREIGN KEY (quote_id) REFERENCES Quotes(quote_id) ON DELETE CASCADE
      )
      ''');

    await db.execute('''
      CREATE TABLE Inventory (
        item_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        condition TEXT NOT NULL DEFAULT 'New',
        serial_number TEXT,
        image_path TEXT
      )
      ''');

    await db.execute('''
      CREATE TABLE Packages (
        package_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        details TEXT NOT NULL,
        price REAL NOT NULL
      )
      ''');

    // Seed some demo data only in debug builds. Seeding in release builds
    // can surprise users after reinstall (system backup/restore or fresh
    // database creation). Guarding by kDebugMode keeps this helpful during
    // development without affecting production installs.
    // No seeded demo data by default. Seeding demo clients/packages was
    // removed to avoid surprising users by creating sample clients on
    // fresh installs. If you need demo data for development, add a
    // developer-only import or enable seeding in a debug-only helper.
      
    await db.execute('''
      CREATE TABLE BookingInventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        booking_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES Inventory(item_id) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Upgrade path to version 3: enforce unique emails.
    // Strategy: remove duplicate rows (keep the one with lowest client_id),
    // then create a UNIQUE index on the email column.
    if (oldVersion < 3) {
      try {
        await db.transaction((txn) async {
          // Find emails with more than one row and the id to keep
          final duplicates = await txn.rawQuery('''
            SELECT email, MIN(client_id) AS keep_id
            FROM Clients
            GROUP BY email
            HAVING COUNT(*) > 1
          ''');

          for (final row in duplicates) {
            final email = row['email'] as String?;
            final keepId = row['keep_id'];
            if (email == null || keepId == null) continue;
            await txn.rawDelete('DELETE FROM Clients WHERE email = ? AND client_id != ?', [email, keepId]);
          }

          // Create unique index to enforce uniqueness going forward
          await txn.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_clients_email ON Clients(email)');
        });
      } catch (e) {
        if (kDebugMode) debugPrint('Error upgrading database to enforce unique email: $e');
        // If migration fails, do not crash — the app can still operate,
        // but new databases will have the UNIQUE constraint and existing
        // ones may require manual intervention.
      }
    }
  }
}
