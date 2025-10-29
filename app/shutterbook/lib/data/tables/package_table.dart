// Shutterbook — package_table.dart
// Database helpers for package records used during quote creation.
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/package.dart';

class PackageTable {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertPackage(Package package) async {
    Database db = await dbHelper.database;
    return await db.insert(
      'Packages',
      package.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Package?> getPackageById(int id) async {
    Database db = await dbHelper.database;
    final maps = await db.query(
      'Packages',
      where: 'package_id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Package.fromMap(maps.first);
    }

    return null;
  }

  Future<List<Package>> getAllPackages() async {
    Database db = await dbHelper.database;
    final maps = await db.query('Packages', orderBy: 'name DESC');
    return maps.map((m) => Package.fromMap(m)).toList();
  }

  Future<List<Package>> getPackagesPaged(int limit, int offset) async {
    final db = await dbHelper.database;
    final maps = await db.query('Packages', limit: limit, offset: offset);
    return maps.map((m) => Package.fromMap(m)).toList();
  }

  Future<int> updatePackage(Package package) async {
    final db = await dbHelper.database;
    return await db.update(
      'Packages',
      package.toMap(),
      where: 'package_id = ?',
      whereArgs: [package.id],
    );
  }

  Future<int> deletePackages(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'Packages',
      where: 'package_id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getPackageCount() async {
    final db = await dbHelper.database;
    final count = await db.rawQuery('SELECT COUNT(*) FROM Packages');
    return Sqflite.firstIntValue(count) ?? 0;
  }
}
