// Shutterbook — data model: Package
// Minor helper model used while building quotes. Kept intentionally
// lightweight and serializable for ease of persistence.
class Package {
  int? id;
  String name;
  String details;
  double price;

  Package({
    this.id,
    required this.name,
    required this.details,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {'package_id': id, 'name': name, 'details': details, 'price': price};
  }

  factory Package.fromMap(Map<String, dynamic> map) {
    return Package(
      id: map['package_id'],
      name: map['name'],
      details: map['details'],
      price: map['price'],
    );
  }
}
