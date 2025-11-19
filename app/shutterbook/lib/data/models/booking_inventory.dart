class BookingInventory {
  final int? id; // primary key
  final int bookingId;
  final int itemId;
  final int quantity;

  BookingInventory({
    this.id,
    required this.bookingId,
    required this.itemId,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'booking_id': bookingId,
      'item_id': itemId,
      'quantity': quantity,
    };
  }

  factory BookingInventory.fromMap(Map<String, dynamic> map) {
    return BookingInventory(
      id: map['id'],
      bookingId: map['booking_id'],
      itemId: map['item_id'],
      quantity: map['quantity'],
    );
  }
}