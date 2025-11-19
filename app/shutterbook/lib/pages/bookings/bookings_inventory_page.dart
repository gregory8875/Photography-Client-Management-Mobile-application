import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/tables/inventory_table.dart';
import '../../data/tables/booking_inventory_table.dart';
import '../../data/models/item.dart';
import '../inventory/inventory.dart';
// removed unused import: '../../data/models/booking_inventory.dart'

class BookingInventoryPage extends StatefulWidget {
  final int bookingId;

  const BookingInventoryPage({super.key, required this.bookingId});

  @override
  State<BookingInventoryPage> createState() => _BookingInventoryPageState();
}

class _BookingInventoryPageState extends State<BookingInventoryPage> {
  final InventoryTable _inventoryTable = InventoryTable();
  final BookingInventoryTable _bookingInventoryTable = BookingInventoryTable();

  List<Item> _allItems = [];
  List<Item> _filteredItems = [];
  Set<int> _selectedItemIds = {};
  Set<int> _originalSelectedItemIds = {};
  String _searchQuery = '';

  bool get _hasUnsavedChanges =>
      !_setEquals(_selectedItemIds, _originalSelectedItemIds);

  bool _setEquals(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final allItems = await _inventoryTable.getAllItems();
    final bookingItems =
        await _bookingInventoryTable.getItemsForBooking(widget.bookingId);

    setState(() {
      _allItems = allItems;
      _filteredItems = allItems;
      _selectedItemIds = bookingItems.map((e) => e.itemId).toSet();
      _originalSelectedItemIds = Set.from(_selectedItemIds);
    });
  }

  Future<void> _saveSelection() async {
    // Capture messenger before any awaits to avoid using BuildContext
    // across async gaps (silences analyzer hint).
    final messenger = ScaffoldMessenger.of(context);

    await _bookingInventoryTable.deleteItemsForBooking(widget.bookingId);

    for (final itemId in _selectedItemIds) {
      await _bookingInventoryTable.addItemToBooking(widget.bookingId, itemId);
    }

    setState(() {
      _originalSelectedItemIds = Set.from(_selectedItemIds);
    });

    if (mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Booking inventory updated successfully')),
      );
    }
  }

  void _filterItems(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredItems = _allItems.where((item) {
    return item.name.toLowerCase().contains(_searchQuery) ||
      item.category.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content:
            const Text('You have unsaved changes. Do you want to save before exiting?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Save and exit
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Exit without saving
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, null), // Cancel dialog
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      await _saveSelection();
      if (!mounted) return false;
      Navigator.pop(context);
      return false; // prevent double pop
    } else if (shouldExit == false) {
      if (!mounted) return false;
      Navigator.pop(context);
      return false;
    }

    return false; // Stay on page if canceled
  }

  @override
  Widget build(BuildContext context) {
    final selectedItems =
        _allItems.where((item) => _selectedItemIds.contains(item.id)).toList();

    // PopScope is recommended in newer Flutter versions, but keep WillPopScope
    // for compatibility; suppress the deprecation info at this call site.
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
  child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Inventory Items'),
              Text(
                '${_selectedItemIds.length} item(s) selected',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSelection,
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by name or category...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                onChanged: _filterItems,
              ),
            ),

            // Selected items preview
            if (selectedItems.isNotEmpty)
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selected Items:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedItems.length,
                        itemBuilder: (context, index) {
                          final item = selectedItems[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: item.imagePath != null && item.imagePath!.isNotEmpty
                                    ? Image.file(
                                        File(item.imagePath!),
                                        height: 100,           
                                        width: 100,            
                                        fit: BoxFit.cover,
                                      )
                                      : const Icon(
                                        Icons.image_not_supported,
                                        size: 80,             
                                        color: Colors.grey,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.name,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Filtered grid of items
            Expanded(
              child: _filteredItems.isEmpty
                  ? const Center(child: Text('No items found'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final selected = _selectedItemIds.contains(item.id);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selectedItemIds.remove(item.id);
                              } else {
                                _selectedItemIds.add(item.id!);
                              }
                            });
                          },
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                    height: 120,
                                    width: double.infinity,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                      child: item.imagePath != null && item.imagePath!.isNotEmpty
                                          ? Image.file(
                                              File(item.imagePath!),
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                size: 60,
                                                color: Colors.grey,
                                              ),
                                            ),
                                    ),
                                  ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          Text(
                                            item.category,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(5),
                                    child: const Icon(Icons.check,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              // Open the full Inventory page with the Add dialog shown, then
              // refresh local data when returning so newly added items are
              // available to attach to this booking.
              final nav = Navigator.of(context);
              await nav.push<bool>(MaterialPageRoute(
                builder: (_) => const InventoryPage(embedded: false, openAddOnLoad: true),
              ));
              if (!mounted) return;
              await _loadData();
            },
            backgroundColor: const Color(0xFF2E7D32),
            tooltip: 'Add inventory item',
            child: const Icon(Icons.add),
          ),
      ),
    );
  }
}