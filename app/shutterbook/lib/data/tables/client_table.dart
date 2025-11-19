// Shutterbook — client_table.dart
// Thin wrapper around SQLite for client CRUD operations. Use this class
// from UI code to fetch, insert and update clients. Keeps SQL details
// isolated from the UI layer.
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/client.dart';

class ClientTable {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertClient(Client client) async {
    Database db = await dbHelper.database;
    return await db.insert(
      'Clients',
      client.toMap(),
      // Abort on conflict so higher layers can detect duplicates and react
      // (previously used replace which silently overwrote an existing row).
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Client?> getClientById(int id) async {
    Database db = await dbHelper.database;
    final maps = await db.query(
      'Clients',
      where: 'client_id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Client.fromMap(maps.first);
    }

    return null;
  }

  Future<Client?> getClientByEmail(String email) async {
    Database db = await dbHelper.database;
    final maps = await db.query(
      'Clients',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return Client.fromMap(maps.first);
    }

    return null;
  }

  Future<Client?> getClientByQuoteId(int quoteId) async {
    Database db = await dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
        SELECT Clients.* 
        FROM Clients 
        INNER JOIN Quotes ON Clients.client_id = Quotes.client_id 
        WHERE Quotes.quote_id = ?
      ''',
      [quoteId],
    );

    if (result.isNotEmpty) {
      return Client.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<List<Client>> getAllClients() async {
    Database db = await dbHelper.database;
    final maps = await db.query('Clients');
    return maps.map((m) => Client.fromMap(m)).toList();
  }

  Future<List<Client>> getClientsPaged(int limit, int offset) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'Clients',
      // orderBy: '', // Can add ordering here if we'd like
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Client.fromMap(m)).toList();
  }

  Future<int> updateClient(Client client) async {
    final db = await dbHelper.database;
    return await db.update(
      'Clients',
      client.toMap(),
      where: 'client_id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int id) async {
    final db = await dbHelper.database;
    return await db.delete('Clients', where: 'client_id = ?', whereArgs: [id]);
  }

  Future<int> getClientCount() async {
    final db = await dbHelper.database;
    final count = await db.rawQuery('SELECT COUNT(*) FROM Clients');
    return Sqflite.firstIntValue(count) ?? 0;
  }
}
