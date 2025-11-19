class BookingWithClient {
  final int bookingId;
  final int clientId;
  final int? quoteId;
  final DateTime bookingDate;
  final String status;
  final DateTime? createdAt;
  final String? clientName;

  BookingWithClient({
    required this.bookingId,
    required this.clientId,
    this.quoteId,
    required this.bookingDate,
    required this.status,
    this.createdAt,
    this.clientName,
  });

  factory BookingWithClient.fromMap(Map<String, dynamic> m) {
    final bookingId = m['booking_id'] is int ? m['booking_id'] as int : int.tryParse('${m['booking_id']}') ?? 0;
    final clientId = m['client_id'] is int ? m['client_id'] as int : int.tryParse('${m['client_id']}') ?? 0;
    final quoteId = m['quote_id'] != null ? (m['quote_id'] is int ? m['quote_id'] as int : int.tryParse('${m['quote_id']}')) : null;
    final bookingDateRaw = m['booking_date'] ?? m['bookingDate'] ?? '';
    DateTime bookingDate;
    try {
      bookingDate = bookingDateRaw is DateTime ? bookingDateRaw : DateTime.parse(bookingDateRaw.toString());
    } catch (_) {
      bookingDate = DateTime.now();
    }
    final status = (m['status'] ?? 'Scheduled').toString();
    DateTime? created;
    if (m['created_at'] != null) {
      try {
        created = m['created_at'] is DateTime ? m['created_at'] : DateTime.parse(m['created_at'].toString());
      } catch (_) {
        created = null;
      }
    }
    final clientName = m['client_name']?.toString();

    return BookingWithClient(
      bookingId: bookingId,
      clientId: clientId,
      quoteId: quoteId,
      bookingDate: bookingDate,
      status: status,
      createdAt: created,
      clientName: clientName,
    );
  }
}