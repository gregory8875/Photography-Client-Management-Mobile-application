// Shutterbook — data model: Booking
// Represents a scheduled booking (appointment). Stored via
// BookingTable; used in the dashboard and bookings screens.
class Booking {
  int? bookingId;
  int clientId;
  int? quoteId;
  DateTime bookingDate;
  String status;
  DateTime? createdAt;

  String? clientName;

  Booking({
    this.bookingId,
    required this.clientId,
    required this.bookingDate,
    this.quoteId,
    this.status = 'Scheduled',
    this.createdAt,
    this.clientName,
  });

  Map<String, dynamic> toMap() {
  return {
    'booking_id': bookingId,
    'client_id': clientId,
    'quote_id': quoteId,
    'booking_date': bookingDate.toIso8601String(),
    'status': status,
    'created_at': createdAt?.toIso8601String(),
  };
}

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
  bookingId: map['booking_id'],
  clientId: map['client_id'],
  quoteId: map['quote_id'],
  bookingDate: DateTime.parse(map['booking_date']),
  status: map['status'] ?? 'Scheduled',
  createdAt: map['created_at'] != null
  ? DateTime.tryParse(map['created_at'])
  : null,
  clientName: map['client_name'],
  );
  }
  
}


