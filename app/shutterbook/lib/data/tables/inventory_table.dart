// Shutterbook — inventory_table.dart
// Persistence helpers for inventory items. Keeps all SQL interactions
// related to the Inventory table in one place.
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/item.dart';

class InventoryTable {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertItem(Item item) async {
    Database db = await dbHelper.database;
    return await db.insert(
      'Inventory',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Item?> getItemById(int id) async {
    Database db = await dbHelper.database;
    final maps = await db.query(
      'Inventory',
      where: 'item_id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Item.fromMap(maps.first);
    }

    return null;
  }

  Future<List<Item>> getAllItems() async {
    Database db = await dbHelper.database;
    final maps = await db.query('Inventory');
    return maps.map((m) => Item.fromMap(m)).toList();
  }

  Future<List<Item>> getItemsPaged(int limit, int offset) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'Inventory',
      // orderBy: '', // Can add ordering here if we'd like
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Item.fromMap(m)).toList();
  }

  Future<int> updateItem(Item item) async {
    final db = await dbHelper.database;
    return await db.update(
      'Inventory',
      item.toMap(),
      where: 'item_id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await dbHelper.database;
    return await db.delete('Inventory', where: 'item_id = ?', whereArgs: [id]);
  }

  Future<int> getItemCount() async {
    final db = await dbHelper.database;
    final count = await db.rawQuery('SELECT COUNT(*) FROM Inventory');
    return Sqflite.firstIntValue(count) ?? 0;
  }
}
