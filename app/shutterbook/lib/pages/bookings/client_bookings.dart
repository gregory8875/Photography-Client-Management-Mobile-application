// Shutterbook — Client-specific bookings view
// Shows bookings filtered to a single client. Used when drilling down
// from clients or quick links.
import 'package:flutter/material.dart';
import 'package:shutterbook/theme/ui_styles.dart';
import '../../data/models/client.dart';
import '../../data/models/booking.dart';
import '../../data/tables/booking_table.dart';

class ClientBookingsPage extends StatefulWidget {
  final Client client;
  const ClientBookingsPage({super.key, required this.client});

  @override
  State<ClientBookingsPage> createState() => _ClientBookingsPageState();
}

class _ClientBookingsPageState extends State<ClientBookingsPage> {
  final BookingTable bookingTable = BookingTable();
  List<Booking> bookings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadClientBookings();
  }

  Future<void> _loadClientBookings() async {
    if (widget.client.id == null) {
      setState(() {
        bookings = [];
        loading = false;
      });
      return;
    }
    final data = await bookingTable.getBookingsByClient(widget.client.id!);
    setState(() {
      bookings = data;
      loading = false;
    });
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UIStyles.accentAppBar(context, Text('Bookings — ${widget.client.firstName} ${widget.client.lastName}'), 1),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : bookings.isEmpty
          ? const Center(child: Text('No bookings for this client'))
          : ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final b = bookings[index];
                return ListTile(
                  contentPadding: UIStyles.tilePadding,
                  title: Text(_formatDate(b.bookingDate)),
                  subtitle: Text('Status: ${b.status}  •  Quote: ${b.quoteId}'),
                  onTap: () async {
                    // Navigate to the bookings page and ask it to open the edit dialog for this booking.
                    // Capture the navigator before awaiting to avoid using BuildContext across async gaps.
                    final navigator = Navigator.of(context);
                    await navigator.pushNamed(
                      '/bookings',
                      arguments: {'open_booking_id': b.bookingId},
                    );

                    // Refresh the client bookings in case the user edited/deleted a booking.
                    if (!mounted) return;
                    await _loadClientBookings();
                  },
                );
              },
            ),
    );
  }
}
