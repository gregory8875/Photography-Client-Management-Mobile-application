// Shutterbook — Inventory screen
// Embedded-aware InventoryPage: when embedded == true, returns only the page body
// so a parent (e.g., Dashboard) can provide and animate a FAB. When embedded ==
// false, the page returns a Scaffold with its own FAB.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/item.dart';
import '../../data/tables/inventory_table.dart';
import 'items_details_page.dart';

class InventoryPage extends StatefulWidget {
  final bool embedded;
  final bool openAddOnLoad;

  const InventoryPage({super.key, this.embedded = false, this.openAddOnLoad = false});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final InventoryTable _inventoryTable = InventoryTable();
  final ImagePicker _picker = ImagePicker();

  List<Item> _inventory = [];
  List<Item> _filteredInventory = [];

  String _searchQuery = '';
  String _selectedCondition = 'All';

  @override
  void initState() {
    super.initState();
    _loadItems();
    if (widget.openAddOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showAddDialog();
      });
    }
  }

  Future<void> _loadItems() async {
    final items = await _inventoryTable.getAllItems();
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (!mounted) return;
    setState(() {
      _inventory = items;
      _applyFilters();
    });
  }

  void _filterInventory(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void _applyFilters() {
    _filteredInventory = _inventory.where((item) {
      final nameMatch = item.name.toLowerCase().contains(_searchQuery);
      final categoryMatch = item.category.toLowerCase().contains(_searchQuery);
      final conditionMatch = _selectedCondition == 'All' || item.condition == _selectedCondition;
      return (nameMatch || categoryMatch) && conditionMatch;
    }).toList();

    _filteredInventory.sort((a, b) => a.name.compareTo(b.name));
    if (mounted) setState(() {});
  }

  Future<void> _showAddDialog() async {
    String name = '';
    String category = '';
    String condition = 'Good';
    String serialNumber = '';
    String? imagePath;

    Future<void> pickImage() async {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) imagePath = picked.path;
    }

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Inventory Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Name', contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12)),
                  onChanged: (v) => name = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(labelText: 'Category', contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12)),
                  onChanged: (v) => category = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(labelText: 'Serial Number (optional)', contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12)),
                  onChanged: (v) => serialNumber = v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: condition,
                  items: const [
                    DropdownMenuItem(value: 'New', child: Text('New')),
                    DropdownMenuItem(value: 'Excellent', child: Text('Excellent')),
                    DropdownMenuItem(value: 'Good', child: Text('Good')),
                    DropdownMenuItem(value: 'Needs Repair', child: Text('Needs Repair')),
                  ],
                  onChanged: (v) => condition = v ?? 'Good',
                  decoration: const InputDecoration(labelText: 'Condition'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await pickImage();
                        if (mounted) setState(() {});
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Pick Image'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2E7D32), // button background color
                          foregroundColor: Colors.white, // text/icon color
                        ),
                    ),
                    const SizedBox(width: 8),
                    if (imagePath != null) Flexible(child: Text(File(imagePath!).uri.pathSegments.last)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ElevatedButton(
              onPressed: () async {
                final newItem = Item(
                  id: null,
                  name: name.trim(),
                  category: category.trim(),
                  condition: condition.trim(),
                  serialNumber: serialNumber.trim().isEmpty ? null : serialNumber.trim(),
                  imagePath: imagePath,
                );

                // Capture navigator & messenger before any awaits to avoid
                // using BuildContext across async gaps (fix analyzer hint).
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                await _inventoryTable.insertItem(newItem);
                if (!mounted) return;
                navigator.pop();
                await _loadItems();
                messenger.showSnackBar(SnackBar(
                  content: Text('Item "${newItem.name}" added'),
                  backgroundColor: const Color(0xFF2E7D32),
                ));
              },
              style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2E7D32), // button background color
                          foregroundColor: Colors.white, // text/icon color
                        ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Expose methods so parent (Dashboard) can call them via GlobalKey.currentState
  // These are invoked dynamically from the dashboard; keep lightweight wrappers.
  Future<void> openAddDialog() async => _showAddDialog();

  Future<void> refresh() async => _loadItems();

  Widget _buildPageBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search by name or category',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _filterInventory,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list, color: Color(0xFF2E7D32), size: 28),
                tooltip: 'Filter by condition',
                onSelected: (value) {
                  _selectedCondition = value;
                  _applyFilters();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'All', child: Text('All Conditions')),
                  PopupMenuItem(value: 'New', child: Text('New')),
                  PopupMenuItem(value: 'Excellent', child: Text('Excellent')),
                  PopupMenuItem(value: 'Good', child: Text('Good')),
                  PopupMenuItem(value: 'Needs Repair', child: Text('Needs Repair')),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              itemCount: _filteredInventory.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final item = _filteredInventory[index];
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => InventoryDetailsPage(item: item)),
                    );
                    if (!mounted) return;
                    await _loadItems();
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: item.imagePath != null && item.imagePath!.isNotEmpty
                              ? Image.file(File(item.imagePath!), width: double.infinity, fit: BoxFit.cover)
                              : Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('Category: ${item.category}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                              Text('Condition: ${item.condition}', style: TextStyle(fontSize: 13, color: item.condition == 'Needs Repair' ? Colors.red : Colors.green), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageBody = _buildPageBody();
    if (widget.embedded) return pageBody;

    return Scaffold(
      body: pageBody,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add),
      ),
    );
  }
}
