// Shutterbook — data model: Item
// Represents an inventory item. Simple serializable model consumed by the
// inventory screens and persisted by InventoryTable.
class Item {
  int? id;
  String name;
  String category;
  String condition;

  Item({
    this.id,
    required this.name,
    required this.category,
    required this.condition,
  });

  Map<String, dynamic> toMap() {
    return {
      'item_id': id,
      'name': name,
      'category': category,
      'condition': condition,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['item_id'],
      name: map['name'],
      category: map['category'],
      condition: map['condition'],
    );
  }
}
