// Shutterbook — data model: Quote
// Represents a quote created for a client. Small, serializable model used
// by the quotes UI and persisted via QuoteTable.
class Quote {
  int? id;
  int clientId;
  double totalPrice;
  String description;
  DateTime? createdAt;

  Quote({
    this.id,
    required this.clientId,
    required this.totalPrice,
    required this.description,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'quote_id': id,
      'client_id': clientId,
      'total_price': totalPrice,
      'description': description,
    };

    if (createdAt != null) {
      map['created_at'] = createdAt?.toString();
    }

    return map;
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['quote_id'],
      clientId: map['client_id'],
      totalPrice: map['total_price'],
      description: map['description'],
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null
    );
  }
}
