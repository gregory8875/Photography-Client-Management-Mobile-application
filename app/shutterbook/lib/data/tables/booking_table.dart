// Shutterbook — booking_table.dart
// Database access helpers for bookings. CRUD and query helpers used by
// the bookings UI. Keep business logic out of this file; it should only
// translate between Booking models and the SQL layer.
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/booking.dart';

class BookingTable {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertBooking(Booking booking) async {
    final db = await dbHelper.database;
    return await db.insert(
      'Bookings',
      booking.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Booking?> getBookingById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'Bookings',
      where: 'booking_id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) return Booking.fromMap(maps.first);
    return null;
  }

  Future<List<Booking>> getAllBookings() async {
    final db = await dbHelper.database;
    final maps = await db.query('Bookings', orderBy: 'booking_date DESC');
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  Future<List<Booking>> getBookingsByClient(int clientId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'Bookings',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'booking_date DESC',
    );
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  Future<int> updateBooking(Booking booking) async {
    final db = await dbHelper.database;
    return await db.update(
      'Bookings',
      booking.toMap(),
      where: 'booking_id = ?',
      whereArgs: [booking.bookingId],
    );
  }

  Future<int> deleteBooking(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'Bookings',
      where: 'booking_id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getBookingCount() async {
    final db = await dbHelper.database;
    final x = await db.rawQuery('SELECT COUNT(*) FROM Bookings');
    return Sqflite.firstIntValue(x) ?? 0;
  }

  Future<List<Booking>> getBookingsByStatus(String status) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'Bookings',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'booking_date DESC',
    );
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  Future<List<Booking>> getBookingsPaged(int limit, int offset) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'Bookings',
      orderBy: 'booking_date DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  /// Finds bookings that would conflict with the given [when].
  ///
  /// Because the app schedules at hour granularity in the calendar,
  /// we consider any booking within the same hour a potential conflict.
  /// If [excludeBookingId] is provided, that row will be ignored (useful
  /// when editing an existing booking).
  Future<List<Booking>> findHourConflicts(DateTime when, {int? excludeBookingId}) async {
    final db = await dbHelper.database;
    // Define the hour range: [hourStart, hourStart + 1h)
    final hourStart = DateTime(when.year, when.month, when.day, when.hour);
    final hourEnd = hourStart.add(const Duration(hours: 1));
    final where = excludeBookingId == null
        ? 'booking_date >= ? AND booking_date < ?'
        : 'booking_date >= ? AND booking_date < ? AND booking_id <> ?';
    final whereArgs = excludeBookingId == null
        ? [hourStart.toString(), hourEnd.toString()]
        : [hourStart.toString(), hourEnd.toString(), excludeBookingId];

    final maps = await db.query(
      'Bookings',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'booking_date ASC',
    );
    return maps.map((m) => Booking.fromMap(m)).toList();
  }
}
