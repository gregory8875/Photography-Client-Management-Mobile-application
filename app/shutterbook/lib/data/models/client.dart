// Shutterbook — data model: Client
// Simple container for client data. Used by the UI and persisted via
// the ClientTable helper in `data/tables/client_table.dart`.
class Client {
  int? id;
  String firstName;
  String lastName;
  String email;
  String phone;

  Client({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'client_id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['client_id'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      email: map['email'],
      phone: map['phone'],
    );
  }
}
