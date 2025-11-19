// The file uses BuildContext with modal pickers and captured Navigator/ScaffoldMessenger
// in a safe way (we check `mounted` before calling setState / pop). Suppress the
// analyzer warning about BuildContext across async gaps for this file.
// ignore_for_file: use_build_context_synchronously
// Shutterbook — Create/Edit Booking screen
// Form to create or edit booking records. Called from dashboard quick
// actions and the bookings list.
import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/booking.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/services/data_cache.dart';
import 'package:shutterbook/data/tables/booking_table.dart';
import 'package:shutterbook/data/tables/client_table.dart';
import 'package:shutterbook/data/tables/quote_table.dart';
import 'package:shutterbook/pages/bookings/bookings_inventory_page.dart';
import 'package:shutterbook/theme/ui_styles.dart';
import 'package:shutterbook/widgets/client_search_dialog.dart';
import 'package:shutterbook/widgets/section_card.dart';

class CreateBookingPage extends StatefulWidget {
  final Quote? quote; // provided when creating a new booking from a quote
  final Booking? existing; // provided when editing an existing booking

  const CreateBookingPage({super.key, this.quote, this.existing});

  @override
  State<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends State<CreateBookingPage> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  String _status = 'Scheduled';
  bool _saving = false;
  bool _deleting = false;

  final ClientTable _clientTable = ClientTable();
  final QuoteTable _quoteTable = QuoteTable();
  Client? _selectedClient;
  List<Quote> _clientQuotes = [];
  int? _selectedQuoteId;

  @override
  void initState() {
    super.initState();
    _initDefaults();
  }

  void _initDefaults() {
    final now = DateTime.now();
    final existing = widget.existing;

    if (existing != null) {
      _selectedDate = DateTime(existing.bookingDate.year, existing.bookingDate.month, existing.bookingDate.day);
      _selectedStartTime = TimeOfDay.fromDateTime(existing.bookingDate);
      _selectedEndTime = _defaultEndTimeFor(_selectedStartTime!);
      _status = _mapStatus(existing.status);

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        Client? client;
        List<Quote> quotes = [];
        try {
          client = await _clientTable.getClientById(existing.clientId);
          if (client?.id != null) {
            quotes = await _quoteTable.getQuotesByClient(client!.id!);
          }
        } catch (_) {}
        if (!mounted) return;
        setState(() {
          _selectedClient = client;
          _clientQuotes = quotes;
          _selectedQuoteId = existing.quoteId ?? (quotes.isNotEmpty ? quotes.first.id : null);
        });
      });
      return;
    }

    final baseHour = now.hour.clamp(8, 17);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedStartTime = TimeOfDay(hour: baseHour, minute: 0);
    _selectedEndTime = _defaultEndTimeFor(_selectedStartTime!);

    if (widget.quote != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        Client? client;
        List<Quote> quotes = [];
        try {
          client = await _clientTable.getClientById(widget.quote!.clientId);
          quotes = await _quoteTable.getQuotesByClient(widget.quote!.clientId);
        } catch (_) {}
        if (!mounted) return;
        setState(() {
          _selectedClient = client;
          _clientQuotes = quotes.isNotEmpty ? quotes : [widget.quote!];
          _selectedQuoteId = widget.quote!.id;
        });
      });
    }
  }

  String _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'finished':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Scheduled';
    }
  }

  TimeOfDay _defaultEndTimeFor(TimeOfDay start) {
    final candidateHour = (start.hour + 1).clamp(0, 23);
    final candidate = TimeOfDay(hour: candidateHour, minute: start.minute);
    if (candidate.hour > 18 || (candidate.hour == 18 && candidate.minute > 0)) {
      return const TimeOfDay(hour: 18, minute: 0);
    }
    return candidate;
  }

  DateTime? _combine(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _openClientPicker() async {
    final picked = await showDialog<Client?>(
      context: context,
      builder: (_) => const ClientSearchDialog(),
    );
    if (picked == null) return;

    setState(() {
      _selectedClient = picked;
      _clientQuotes = [];
      _selectedQuoteId = null;
    });

    try {
      final quotes = await _quoteTable.getQuotesByClient(picked.id!);
      if (!mounted) return;
      setState(() {
        _clientQuotes = quotes;
        _selectedQuoteId = quotes.isNotEmpty ? quotes.first.id : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _clientQuotes = [];
        _selectedQuoteId = null;
      });
      _showSnack('Failed to load quotes for the selected client.', error: true);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _pickStartTime() async {
    final initial = _selectedStartTime ?? const TimeOfDay(hour: 8, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;

    final normalized = TimeOfDay(hour: picked.hour, minute: 0);
    if (normalized.hour < 8 || normalized.hour > 17) {
      _showSnack('Bookings can only start between 08:00 and 17:00.', error: true);
      return;
    }

    setState(() {
      _selectedStartTime = normalized;
      _selectedEndTime = _defaultEndTimeFor(normalized);
    });
  }

  Future<void> _pickEndTime() async {
    final start = _selectedStartTime;
    if (start == null) {
      _showSnack('Select a start time first.', error: true);
      return;
    }

    final initial = _selectedEndTime ?? _defaultEndTimeFor(start);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;

    final normalized = TimeOfDay(hour: picked.hour, minute: 0);
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = normalized.hour * 60 + normalized.minute;

    if (endMinutes <= startMinutes) {
      _showSnack('End time must be after the start time.', error: true);
      return;
    }
    if (normalized.hour > 18 || (normalized.hour == 18 && normalized.minute > 0)) {
      _showSnack('Bookings must finish by 18:00.', error: true);
      return;
    }

    setState(() => _selectedEndTime = normalized);
  }

  void _showSnack(String message, {bool error = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : null,
      ),
    );
  }

  Future<void> _deleteBooking() async {
    final existing = widget.existing;
    if (_deleting || existing?.bookingId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);

    try {
      await BookingTable().deleteBooking(existing!.bookingId!);
      DataCache.instance.clearBookings();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      _showSnack('Failed to delete booking: $e', error: true);
    }
  }

  Future<void> _saveBooking() async {
    if (_saving) return;

    if (_selectedClient == null) {
      _showSnack('Please select a client.', error: true);
      return;
    }
    if (_selectedQuoteId == null) {
      _showSnack('Please select a quote for the selected client.', error: true);
      return;
    }

    final start = _combine(_selectedDate, _selectedStartTime);
    final end = _combine(_selectedDate, _selectedEndTime);

    if (start == null || end == null) {
      _showSnack('Please choose a date, start time and end time.', error: true);
      return;
    }
    if (!end.isAfter(start)) {
      _showSnack('End time must be after the start time.', error: true);
      return;
    }
    if (start.hour < 8 || start.hour > 17) {
      _showSnack('Bookings can only start between 08:00 and 17:00.', error: true);
      return;
    }
    if (end.hour > 18 || (end.hour == 18 && end.minute > 0)) {
      _showSnack('Bookings must finish by 18:00.', error: true);
      return;
    }

    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      DateTime cursor = start;
      while (cursor.isBefore(end)) {
        final conflicts = await BookingTable().findHourConflicts(
          cursor,
          excludeBookingId: widget.existing?.bookingId,
        );
        if (conflicts.isNotEmpty) {
          if (mounted) {
            setState(() => _saving = false);
            _showSnack('Slot ${_formatDateTime(cursor)} is already booked.', error: true);
          }
          return;
        }
        cursor = cursor.add(const Duration(hours: 1));
      }

      if (widget.existing != null && widget.existing!.bookingId != null) {
        await BookingTable().deleteBooking(widget.existing!.bookingId!);
      }

      cursor = start;
      while (cursor.isBefore(end)) {
        final booking = Booking(
          clientId: _selectedClient!.id!,
          quoteId: _selectedQuoteId,
          bookingDate: cursor,
          status: _status.isEmpty ? 'Scheduled' : _status,
          createdAt: widget.existing?.createdAt,
        );
        await BookingTable().insertBooking(booking);
        cursor = cursor.add(const Duration(hours: 1));
      }

      DataCache.instance.clearBookings();

      if (!mounted) return;
      setState(() => _saving = false);

      nav.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Failed to save booking: $e')));
    }
  }

  String _formatDateTime(DateTime dt) {
    const wk = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = wk[dt.weekday - 1];
    final month = mo[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day, ${dt.day} $month • $hour:$min';
  }

  String _dateLabel() {
    if (_selectedDate == null) return 'Select Date';
    return '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}';
  }

  String _timeLabel(TimeOfDay? time, String placeholder) {
    if (time == null) return placeholder;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final theme = Theme.of(context);

    final statusItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled')),
      const DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
      if (isEditing) const DropdownMenuItem(value: 'Completed', child: Text('Completed')),
    ];

    return Scaffold(
      appBar: UIStyles.accentAppBar(context, Text(isEditing ? 'Edit Booking' : 'Create Booking'), 1),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isEditing && widget.quote != null)
                    ListTile(
                      contentPadding: UIStyles.tilePadding,
                      leading: const Icon(Icons.description_outlined),
                      title: Text('Quote #${widget.quote!.id}'),
                      subtitle: Text(widget.quote!.description),
                    ),
                  if (isEditing && widget.existing?.bookingId != null)
                    ListTile(
                      contentPadding: UIStyles.tilePadding,
                      leading: const Icon(Icons.event_note_outlined),
                      title: Text('Booking #${widget.existing!.bookingId}'),
                      subtitle: const Text('Update booking details'),
                    ),
                  const SizedBox(height: 12),
                  Text('Client', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    style: UIStyles.outlineButton(context),
                    onPressed: _openClientPicker,
                    icon: const Icon(Icons.person_search_outlined),
                    label: Text(
                      _selectedClient != null
                          ? '${_selectedClient!.firstName} ${_selectedClient!.lastName}'
                          : 'Select client',
                    ),
                  ),
                  if (_selectedClient != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        [
                          _selectedClient!.email,
                          if (_selectedClient!.phone.isNotEmpty) _selectedClient!.phone,
                        ].join(' • '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _selectedQuoteId,
                    items: _clientQuotes
                        .where((q) => q.id != null)
                        .map(
                          (q) => DropdownMenuItem(
                            value: q.id,
                            child: Text('Quote #${q.id} — ${q.description}'),
                          ),
                        )
                        .toList(),
                    onChanged: _clientQuotes.isEmpty ? null : (val) => setState(() => _selectedQuoteId = val),
                    decoration: const InputDecoration(
                      labelText: 'Quote',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    disabledHint: const Text('Select a client first'),
                  ),
                  if (_clientQuotes.isEmpty && _selectedClient != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Selected client has no quotes. Please create a quote for this client before adding a booking.',
                        style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text('Date & time', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    style: UIStyles.outlineButton(context),
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(_dateLabel()),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: UIStyles.outlineButton(context),
                          onPressed: _pickStartTime,
                          icon: const Icon(Icons.access_time),
                          label: Text(_timeLabel(_selectedStartTime, 'Start time')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: UIStyles.outlineButton(context),
                          onPressed: _pickEndTime,
                          icon: const Icon(Icons.access_time),
                          label: Text(_timeLabel(_selectedEndTime, 'End time')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _status,
                    items: statusItems,
                    onChanged: (val) => setState(() => _status = val ?? 'Scheduled'),
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                  ),
                  if (isEditing && widget.existing?.bookingId != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingInventoryPage(
                              bookingId: widget.existing!.bookingId!,
                            ),
                          ),
                        );
                        if (!mounted) return;
                        _showSnack('Inventory updated for this booking');
                      },
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text('Manage booking inventory'),
                    ),
                  ],
                  if (isEditing && widget.existing?.bookingId != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _deleting ? null : _deleteBooking,
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _saving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    style: UIStyles.primaryButton(context),
                    onPressed: _saveBooking,
                    icon: const Icon(Icons.check),
                    label: Text(isEditing ? 'Save Changes' : 'Create Booking'),
                  ),
          ],
        ),
      ),
    );
  }
}

