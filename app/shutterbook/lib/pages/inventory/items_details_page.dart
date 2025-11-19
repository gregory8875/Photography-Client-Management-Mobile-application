import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/item.dart';
import '../../data/tables/booking_table.dart';
import '../../data/models/booking_with_client.dart';
import '../../data/tables/inventory_table.dart';
import '../../data/services/data_cache.dart';
import 'package:image_picker/image_picker.dart';

class InventoryDetailsPage extends StatefulWidget {
  final Item item;

  const InventoryDetailsPage({super.key, required this.item});

  @override
  State<InventoryDetailsPage> createState() => _InventoryDetailsPageState();
}

class _InventoryDetailsPageState extends State<InventoryDetailsPage> {
  late Future<List<BookingWithClient>> _bookingsFuture;
  //Item for retrieving new item info after edit and save
  late Item _item;
  //helper for refresh
  Future<void> _reloadItem() async {
    final refreshedItem = await InventoryTable().getItemById(_item.id!);
    if (mounted && refreshedItem != null) {
      setState(() {
        _item = refreshedItem;
      });
    }
  }
  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _loadBookings();
  }

  void _loadBookings() {
    setState(() {
      _bookingsFuture = BookingTable().getBookingsForItemWithClientNames(_item.id!); // correct query
    });
  }

  @override
  Widget build(BuildContext context) {

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_item.name),
          bottom: TabBar(
            labelColor: Colors.white, // Color for the active tab text
            unselectedLabelColor: Colors.grey, // Color for inactive tabs
            indicatorColor:  Color(0xFF2E7D32),// Optional: underline color
            tabs: [
              Tab(text: 'Info'),
              Tab(text: 'Bookings'),
            ],
          ),
 
        ),
        body: TabBarView(
          children: [
            // TAB 1 — ITEM INFO
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_item.imagePath != null && _item.imagePath!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_item.imagePath!),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    const Icon(Icons.image_not_supported,
                        size: 100, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(_item.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Category: ${_item.category}'),
                  Text('Condition: ${_item.condition}'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // EDIT BUTTON
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        onPressed: () async {
                          String name = _item.name;
                          String category = _item.category;
                          String condition = _item.condition;
                          String serialNumber = _item.serialNumber ?? '';
                          String? imagePath = _item.imagePath;

                          // Validation error flags
                          String? nameError;
                          String? categoryError;
                          String? conditionError;

                          await showDialog(
                            context: context,
                            builder: (context) {
                              //initialising the text controllers to avoid resetting the cursor
                              final nameController = TextEditingController(text:name);
                              final categoryController = TextEditingController(text:category);
                              final serialController = TextEditingController(text:serialNumber);
                              
                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    title: const Text('Edit Item'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: nameController,
                                            decoration: InputDecoration(labelText: 'Item Name',errorText: nameError,),
                                            onChanged: (val) {
                                              setState(() {
                                                name = val;
                                                nameError = null;
                                              });
                                            },
                                          ),
                                          const SizedBox(height: 16),

                                          TextField(
                                            controller: categoryController,
                                            decoration: InputDecoration(labelText: 'Category',errorText: categoryError,),
                                            onChanged: (val) {
                                              setState(() {
                                                category = val;
                                                categoryError = null;
                                              });
                                            },
                                          ),
                                          const SizedBox(height: 16),

                                          TextField(
                                            controller: serialController,
                                            decoration: const InputDecoration(labelText: 'Serial Number (optional)',),
                                            onChanged: (val) {
                                              setState(() {
                                                serialNumber = val;
                                              });
                                            },
                                          ),
                                          const SizedBox(height: 16),

                                          DropdownButtonFormField<String>(
                                            decoration: InputDecoration(labelText: 'Condition',errorText: conditionError,),
                                            initialValue: condition,
                                            items: ['New', 'Excellent', 'Good', 'Needs Repair']
                                                .map((e) =>
                                                    DropdownMenuItem(value: e, child: Text(e)))
                                                .toList(),
                                            onChanged: (val) {
                                              setState(() {
                                                condition = val ?? 'Good';
                                                conditionError = null;
                                              });
                                            },
                                          ),
                                          const SizedBox(height: 16),

                                          // Show current image
                                          if (imagePath != null && imagePath!.isNotEmpty)
                                            Column(
                                              children: [
                                                Image.file(File(imagePath!),height: 120,fit: BoxFit.cover,),
                                                const SizedBox(height: 8),
                                                TextButton.icon(
                                                  onPressed: () {
                                                    setState(() => imagePath = null);
                                                  },
                                                  icon: const Icon(Icons.delete_outline,color: Colors.red),
                                                  label: const Text('Remove Image',
                                                      style: TextStyle(color: Colors.red)),
                                                ),
                                                const SizedBox(height: 10),
                                              ],
                                            ),

                                          // Change / Add image
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              final picker = ImagePicker();
                                              final picked = await picker.pickImage(
                                                  source: ImageSource.gallery);
                                              if (picked != null) {
                                                setState(() => imagePath = picked.path);
                                              }
                                            },
                                            //styling the button
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(0xFF2E7D32), // button background color
                                              foregroundColor: Colors.white, // text/icon color
                                            ),
                                            icon: const Icon(Icons.image),
                                            label: const Text('Change / Add Image'),
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
                                          // Inline validation per field
                                          setState(() {
                                            nameError = name.trim().isEmpty ? 'Please enter a name.' : null;
                                            categoryError = category.trim().isEmpty? 'Please enter a category.': null;
                                            conditionError = condition.trim().isEmpty? 'Please select a condition.': null;
                                          });

                                          if (nameError != null ||categoryError != null ||conditionError != null) return;

                                          final updatedItem = Item(
                                            id: _item.id,
                                            name: name.trim(),
                                            category: category.trim(),
                                            condition: condition.trim(),
                                            serialNumber: serialNumber.trim().isEmpty? null: serialNumber.trim(),
                                            imagePath: imagePath,
                                          );

                                          // Capture navigator and messenger before async work
                                          final navigator = Navigator.of(context);
                                          final messenger = ScaffoldMessenger.of(context);

                                          await InventoryTable().updateItem(updatedItem);
                                          DataCache.instance.clearInventory();

                                          //Refresh tab info
                                          await _reloadItem(); // refresh state directly
                                          if (!mounted) return;
                                          navigator.pop();

                                          if (!mounted) return;
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text('Item "${_item.name}" updated successfully!'),
                                              backgroundColor: const Color(0xFF2E7D32),
                                            ),
                                          );
                                        },
                                        //styling the button
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF2E7D32), // button background color
                                          foregroundColor: Colors.white, // text/icon color
                                        ),
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                        //styling the button
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2E7D32), // button background color
                          foregroundColor: Colors.white, // text/icon color
                        ),
                      ),

                      // DELETE BUTTON
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () async {
                          // Capture navigator and messenger before any awaits so we
                          // don't use BuildContext across async gaps.
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Item'),
                              content: const Text(
                                  'Are you sure you want to delete this item? This action cannot be undone.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await InventoryTable().deleteItem(_item.id!);
                            DataCache.instance.clearInventory();
                            if (mounted) {
                              navigator.pop(true);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Item "${_item.name}" deleted successfully.'),
                                  backgroundColor: Color(0xFF2E7D32),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),

            // TAB 2 — BOOKINGS TAB
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Linked Bookings',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh bookings',
                        onPressed: _loadBookings,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder(
                    future: _bookingsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No bookings found.'));
                      }

                      final allBookings = snapshot.data!;

                      // Group bookings based on their status
                      final upcoming = allBookings
                          .where((b) =>
                              (b.status.toLowerCase() == 'scheduled' ||
                              b.status.toLowerCase() == 'pending'))
                          .toList();

                      final past = allBookings
                          .where((b) => b.status.toLowerCase() == 'completed' ||
                                        b.status.toLowerCase() == 'complete')
                          .toList();

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Upcoming bookings
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Upcoming Bookings',
                                style:
                                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (upcoming.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('No upcoming bookings.'),
                              )
                            else
                              ...upcoming.map((b) => Card(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: ListTile(
                                      leading:
                                          const Icon(Icons.event_available, color: Color(0xFF2E7D32)),
                                      title: Text(b.clientName ?? 'Unknown Client'),
                                      subtitle: Text(
                                          'On ${b.bookingDate.toLocal()} — ${b.status}'),
                                    ),
                                  )),

                            // Past bookings
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Past Bookings',
                                style:
                                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (past.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('No past bookings.'),
                              )
                            else
                              ...past.map((b) => Card(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: ListTile(
                                      leading:
                                          const Icon(Icons.history, color: Color(0xFF2E7D32)),
                                      title: Text(b.clientName ?? 'Unknown Client'),
                                      subtitle: Text(
                                          'On ${b.bookingDate.toLocal()} — ${b.status}'),
                                    ),
                                  )),
                          ],
                        ),
          );
        },
      ),
    ),
  ],
),
          ],
        ),
      ),
    );
  }
}