// Lightweight in-memory cache for frequently-read tables.
// Keeps a single in-flight Future to avoid duplicate DB hits and allows
// manual refresh when needed. Also includes a tiny optional disk-backed
// client snapshot with TTL to speed cold-starts.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/client.dart';
import '../tables/client_table.dart';
import '../models/booking.dart';
import '../tables/booking_table.dart';
import '../models/item.dart';
import '../tables/inventory_table.dart';

class DataCache {
  DataCache._private();
  static final DataCache instance = DataCache._private();

  // --- Clients (in-memory + optional disk snapshot) ---
  List<Client>? _clients;
  Future<List<Client>>? _clientsFuture;
  static const _kClientsPrefsKey = 'cached_clients';
  static const _kClientsTsKey = 'cached_clients_ts';
  // TTL for disk-backed client cache (24 hours)
  static const int _kClientsTtlMs = 24 * 60 * 60 * 1000;

  /// Returns cached clients if available, otherwise fetches from DB.
  /// If [forceRefresh] is false and a valid disk snapshot exists it will be
  /// returned quickly; otherwise the DB will be queried. Concurrent callers
  /// while a fetch is in-flight will await the same Future.
  Future<List<Client>> getClients({bool forceRefresh = false}) async {
    if (!forceRefresh && _clients != null) return Future.value(_clients);

    // Try a quick disk snapshot if available and not expired
    if (!forceRefresh) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final ts = prefs.getInt(_kClientsTsKey) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        final jsonStr = prefs.getString(_kClientsPrefsKey);
        if (jsonStr != null && (now - ts) < _kClientsTtlMs) {
          final list = (jsonDecode(jsonStr) as List).map((m) => Client.fromMap(Map<String, dynamic>.from(m))).toList();
          _clients = list;
          return _clients!;
        }
      } catch (_) {}
    }

    if (_clientsFuture != null) return _clientsFuture!;

    _clientsFuture = ClientTable().getAllClients().then((list) async {
      _clients = list;
      _clientsFuture = null;
      // update disk snapshot asynchronously
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kClientsPrefsKey, jsonEncode(list.map((c) => c.toMap()).toList()));
        await prefs.setInt(_kClientsTsKey, DateTime.now().millisecondsSinceEpoch);
      } catch (_) {}
      return list;
    }).catchError((e) {
      _clientsFuture = null;
      throw e;
    });
    return _clientsFuture!;
  }

  void clearClients() {
    _clients = null;
    _clientsFuture = null;
    unawaited(_purgePersistedClients());
  }

  // --- Bookings (in-memory only) ---
  List<Booking>? _bookings;
  Future<List<Booking>>? _bookingsFuture;
  // Incremented when bookings are cleared so UI can listen and refresh.
  final ValueNotifier<int> bookingsVersion = ValueNotifier<int>(0);

  Future<List<Booking>> getBookings({bool forceRefresh = false}) {
    if (!forceRefresh && _bookings != null) return Future.value(_bookings);
    if (_bookingsFuture != null) return _bookingsFuture!;
    _bookingsFuture = BookingTable().getAllBookings().then((list) {
      _bookings = list;
      _bookingsFuture = null;
      return list;
    }).catchError((e) {
      _bookingsFuture = null;
      throw e;
    });
    return _bookingsFuture!;
  }

  void clearBookings() {
    _bookings = null;
    bookingsVersion.value++;
  }

  // --- Inventory (in-memory only) ---
  List<Item>? _inventory;
  Future<List<Item>>? _inventoryFuture;

  Future<List<Item>> getInventory({bool forceRefresh = false}) {
    if (!forceRefresh && _inventory != null) return Future.value(_inventory);
    if (_inventoryFuture != null) return _inventoryFuture!;
    _inventoryFuture = InventoryTable().getAllItems().then((list) {
      _inventory = list;
      _inventoryFuture = null;
      return list;
    }).catchError((e) {
      _inventoryFuture = null;
      throw e;
    });
    return _inventoryFuture!;
  }

  void clearInventory() {
    _inventory = null;
  }

  /// Clear all in-memory caches (does not touch disk snapshot except clients logic)
  void clearAll() {
    clearClients();
    clearBookings();
    clearInventory();
  }

  Future<void> _purgePersistedClients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kClientsPrefsKey);
      await prefs.remove(_kClientsTsKey);
    } catch (_) {}
  }
}
