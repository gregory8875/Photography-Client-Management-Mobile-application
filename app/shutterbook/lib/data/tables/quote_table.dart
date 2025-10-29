// Shutterbook — quote_table.dart
// Simple persistence helper for quotes. Use this API from the UI layer
// to read and write quote records without touching raw SQL.
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/quote.dart';

class QuoteTable {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertQuote(Quote quote) async {
    Database db = await dbHelper.database;
    return await db.insert(
      'Quotes',
      quote.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Quote?> getQuoteById(int id) async {
    Database db = await dbHelper.database;
    final maps = await db.query(
      'Quotes',
      where: 'quote_id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Quote.fromMap(maps.first);
    }

    return null;
  }

  Future<List<Quote>> getAllQuotes() async {
    Database db = await dbHelper.database;
    final maps = await db.query('Quotes', orderBy: 'created_at DESC');
    return maps.map((m) => Quote.fromMap(m)).toList();
  }

  Future<List<Quote>> getQuotesPaged(int limit, int offset) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'Quotes',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Quote.fromMap(m)).toList();
  }

  Future<List<Quote>> getQuotesByClient(int clientId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'Quotes',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Quote.fromMap(m)).toList();
  }

  Future<int> updateQuote(Quote quote) async {
    final db = await dbHelper.database;
    return await db.update(
      'Quotes',
      quote.toMap(),
      where: 'quote_id = ?',
      whereArgs: [quote.id],
    );
  }

  Future<int> deleteQuotes(int id) async {
    final db = await dbHelper.database;
    return await db.delete('Quotes', where: 'quote_id = ?', whereArgs: [id]);
  }

  Future<int> getQuoteCount() async {
    final db = await dbHelper.database;
    final count = await db.rawQuery('SELECT COUNT(*) FROM Quotes');
    return Sqflite.firstIntValue(count) ?? 0;
  }
 
  Future<List<Map<String, dynamic>>> searchQuotesByClientName(String query) async {
    
  final db = await dbHelper.database;

  final results = await db.rawQuery('''
    SELECT Quotes.*, Clients.name AS client_name
    FROM Quotes
    JOIN Clients ON Quotes.clientId = Clients.id
    WHERE Clients.name LIKE ?
    ORDER BY Quotes.created_at DESC
  ''', ['%$query%']);

  return results;
}






}


