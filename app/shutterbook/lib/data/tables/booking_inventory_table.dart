import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/booking_inventory.dart';

class BookingInventoryTable {
  final dbHelper = DatabaseHelper.instance;

  // Insert a link between booking and inventory item
  Future<int> addItemToBooking(int bookingId, int itemId, {int quantity = 1}) async {
    final db = await dbHelper.database;

    return await db.insert(
      'BookingInventory',
      {
        'booking_id': bookingId,
        'item_id': itemId,
        'quantity': quantity,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all inventory items linked to a booking
  Future<List<BookingInventory>> getItemsForBooking(int bookingId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'BookingInventory',
      where: 'booking_id = ?',
      whereArgs: [bookingId],
    );

    return maps.map((m) => BookingInventory.fromMap(m)).toList();
  }

  // Delete all items for a booking (used when editing or deleting booking)
  Future<int> deleteItemsForBooking(int bookingId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'BookingInventory',
      where: 'booking_id = ?',
      whereArgs: [bookingId],
    );
  }

  // Remove one item link
  Future<int> removeItemFromBooking(int bookingId, int itemId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'BookingInventory',
      where: 'booking_id = ? AND item_id = ?',
      whereArgs: [bookingId, itemId],
    );
  }

  //For showing item booking history
  Future<List<int>> getBookingsForItem(int itemId) async {
  final db = await dbHelper.database;
  final maps = await db.query(
    'BookingInventory',
    where: 'item_id = ?',
    whereArgs: [itemId],
  );
  return maps.map((m) => m['booking_id'] as int).toList();
}
}