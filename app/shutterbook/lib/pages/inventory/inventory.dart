// Shutterbook — Inventory screen
// Manage inventory items (add/edit/remove) used in quotes and bookings.
import 'package:flutter/material.dart';
import 'package:shutterbook/theme/ui_styles.dart';
import '../../data/models/item.dart';
import '../../data/tables/inventory_table.dart';
import '../../data/services/data_cache.dart';
import '../../widgets/section_card.dart';

class InventoryPage extends StatefulWidget {
  final bool embedded;
  // if true, open the add dialog automatically after the page loads
  final bool openAddOnLoad;
  const InventoryPage({super.key, this.embedded = false, this.openAddOnLoad = false});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final InventoryTable _inventoryTable = InventoryTable();
  List<Item> _inventory = [];
  List<Item> _filteredInventory = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
    if (widget.openAddOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _addItem();
      });
    }
  }

  Future<void> _loadItems() async {
    try {
      final items = await DataCache.instance.getInventory();
      setState(() {
        _inventory = items;
        _filteredInventory = items;
      });
      return;
    } catch (_) {}
  final items = await _inventoryTable.getAllItems();
    setState(() {
      _inventory = items;
      _filteredInventory = items;
    });
  }

  // allow parent to refresh items when embedded
  Future<void> refresh() async => _loadItems();

  // allow parent to open the add dialog when embedded
  Future<void> openAddDialog() async => _addItem();

  void _filterInventory(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredInventory = _inventory.where((item) {
        return item.name.toLowerCase().contains(_searchQuery) ||
            item.condition.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  Future<void> _addItem() async {
    String name = '';
    String category = '';
    String condition = 'Good';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Inventory Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Item Name'),
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Category'),
                  onChanged: (val) => category = val,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Condition'),
                  initialValue: 'Good',
                  items: ['New', 'Excellent', 'Good', 'Needs Repair']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => condition = val ?? 'Good',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                final newItem = Item(
                  name: name,
                  category: category,
                  condition: condition,
                );
                await _inventoryTable.insertItem(newItem);
                    DataCache.instance.clearInventory();
                if (nav.mounted) nav.pop();
                _loadItems();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editItem(Item item) async {
    String name = item.name;
    String category = item.category;
    String condition = item.condition;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  onChanged: (val) => category = val,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Condition'),
                  initialValue: condition,
                  items: ['New', 'Excellent', 'Good', 'Needs Repair']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => condition = val ?? 'Good',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                final updatedItem = Item(
                  id: item.id,
                  name: name,
                  category: category,
                  condition: condition,
                );
                await _inventoryTable.updateItem(updatedItem);
                    DataCache.instance.clearInventory();
                if (nav.mounted) nav.pop();
                _loadItems();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    ) ?? false;
    if (!confirm) return;
    await _inventoryTable.deleteItem(id);
    DataCache.instance.clearInventory();
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pageBody = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search by name or condition',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.inputDecorationTheme.fillColor,
            ),
            onChanged: _filterInventory,
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
                return SectionCard(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Category: ${item.category}'),
                        Text(
                          'Condition: ${item.condition}',
                          style: TextStyle(
                            color: item.condition == 'Needs Repair'
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: theme.colorScheme.primary,
                              ),
                              onPressed: () => _editItem(item),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: theme.colorScheme.error,
                              ),
                              onPressed: () => _deleteItem(item.id!),
                            ),
                          ],
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

    return widget.embedded
        ? pageBody
        : Scaffold(
            appBar: UIStyles.accentAppBar(context, const Text('Inventory'), 4),
            body: pageBody,
            floatingActionButton: FloatingActionButton(
              onPressed: _addItem,
              tooltip: 'Add',
              child: const Icon(Icons.add),
            ),
          );
  }
}
