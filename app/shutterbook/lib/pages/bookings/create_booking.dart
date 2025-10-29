// The file uses BuildContext with modal pickers and captured Navigator/ScaffoldMessenger
// in a safe way (we check `mounted` before calling setState / pop). Suppress the
// analyzer warning about BuildContext across async gaps for this file.
// ignore_for_file: use_build_context_synchronously
// Shutterbook — Create/Edit Booking screen
// Form to create or edit booking records. Called from dashboard quick
// actions and the bookings list.
import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/theme/ui_styles.dart';
import 'package:shutterbook/data/models/booking.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/tables/booking_table.dart';
import 'package:shutterbook/data/tables/client_table.dart';
import 'package:shutterbook/widgets/client_search_dialog.dart';
import 'package:shutterbook/data/tables/quote_table.dart';
import '../../widgets/section_card.dart';
import 'package:shutterbook/data/services/data_cache.dart';

class CreateBookingPage extends StatefulWidget {
  final Quote? quote; // provided when creating a new booking from a quote
  final Booking? existing; // provided when editing an existing booking

  const CreateBookingPage({super.key, this.quote, this.existing});

  @override
  State<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends State<CreateBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _statusController = TextEditingController(text: 'Scheduled');

  // controllers for read-only display fields so they update when state changes
  final TextEditingController _clientDisplayController = TextEditingController();
  final TextEditingController _quoteDisplayController = TextEditingController();

  DateTime? _selectedDateTime;
  bool _saving = false;

  // client/quote selection when creating without a provided quote
  final ClientTable _clientTable = ClientTable();
  final QuoteTable _quoteTable = QuoteTable();
  // cached quotes for selected client
  List<Quote> _clientQuotes = [];
  Client? _selectedClient;
  int? _selectedQuoteId;

  @override
  void initState() {
    super.initState();

    // If editing, prefill fields
    final existing = widget.existing;
    if (existing != null) {
      _statusController.text = existing.status;
      _selectedDateTime = existing.bookingDate;
    } else {
      // creating from quote
      _statusController.text = 'Scheduled';
      if (widget.quote != null) {
        // if created from a quote, preselect that quote and load the client
        _selectedQuoteId = widget.quote!.id;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            final c = await _clientTable.getClientById(widget.quote!.clientId);
            if (c != null && mounted) {
              setState(() => _selectedClient = c);
            }
          } catch (_) {}
        });
      }
    }

    // initialize read-only controllers
    _clientDisplayController.text = _computeClientDisplay();
    _quoteDisplayController.text = _computeQuoteDisplay();
  }

  @override
  void dispose() {
    _statusController.dispose();
    _clientDisplayController.dispose();
    _quoteDisplayController.dispose();
    super.dispose();
  }

      Future<void> _openClientSearch() async {
        final selected = await showDialog<Client?>(context: context, builder: (_) => const ClientSearchDialog());

        if (selected != null && mounted) {
          setState(() {
            _selectedClient = selected;
          });

          try {
            final q = await _quoteTable.getQuotesByClient(selected.id!);
            if (!mounted) return;
            setState(() {
              _clientQuotes = q;
              _selectedQuoteId = q.isNotEmpty ? q.first.id : null;
            });
          } catch (_) {}

          // refresh display controllers
          if (mounted) {
            _clientDisplayController.text = _computeClientDisplay();
            _quoteDisplayController.text = _computeQuoteDisplay();
          }
        }
      }

      // pick date and time
      Future<void> _pickDateTime() async {
        final now = DateTime.now();
        final initialDate = _selectedDateTime ?? now;

        final pickedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 3),
        );
        if (pickedDate == null) return;

        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(initialDate),
        );
        if (pickedTime == null) return;

        final combined = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (!mounted) return;
        setState(() => _selectedDateTime = combined);
      }

      Future<void> _saveBooking() async {
        if (!_formKey.currentState!.validate()) return;
        if (_selectedDateTime == null) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            const SnackBar(content: Text('Please select a date and time')),
          );
          return;
        }

        setState(() => _saving = true);
        final nav = Navigator.of(context);

        // Check for potential double booking in the same hour.
        final dt = _selectedDateTime!;
        int? excludeIdForEdit = widget.existing?.bookingId;
        final conflicts = await BookingTable().findHourConflicts(dt, excludeBookingId: excludeIdForEdit);
        if (conflicts.isNotEmpty) {
          // Ask user whether to proceed or go back to edit.
          final proceed = await showDialog<bool>(
                context: context,
                builder: (ctx) {
                  final theme = Theme.of(ctx);
                  String whenStr = _formatDateTime(dt);
                  return AlertDialog(
                    title: const Text('Possible double booking'),
                    content: Text(
                      'There is already ${conflicts.length} booking(s) in this time slot (hour) on $whenStr.\n\nYou can edit the time or proceed and allow a double booking.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Edit time'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text('Proceed', style: TextStyle(color: theme.colorScheme.primary)),
                      ),
                    ],
                  );
                },
              ) ??
              false;
          if (!proceed) {
            if (mounted) setState(() => _saving = false);
            return;
          }
        }

        if (widget.existing != null) {
          // Update existing booking
          final existing = widget.existing!;
          final updated = Booking(
            bookingId: existing.bookingId,
            clientId: existing.clientId,
            quoteId: existing.quoteId,
            bookingDate: _selectedDateTime!,
            status: _statusController.text.trim().isEmpty ? 'Scheduled' : _statusController.text.trim(),
            createdAt: existing.createdAt,
          );
          await BookingTable().updateBooking(updated);
          DataCache.instance.clearBookings();
        } else {
          // Create booking: support creating from provided quote or free-form selection
          int? clientId;
          int? quoteId;
          if (widget.quote != null) {
            clientId = widget.quote!.clientId;
            quoteId = widget.quote!.id;
          } else {
            // require user to pick client and quote in free-form mode
            clientId = _selectedClient?.id;
            quoteId = _selectedQuoteId;
            if (clientId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a client')));
              setState(() => _saving = false);
              return;
            }
          }

          final booking = Booking(
            clientId: clientId,
            quoteId: quoteId,
            bookingDate: _selectedDateTime!,
            status: _statusController.text.trim().isEmpty ? 'Scheduled' : _statusController.text.trim(),
          );
          await BookingTable().insertBooking(booking);
          DataCache.instance.clearBookings();
        }

        if (!mounted) return;
        setState(() => _saving = false);

        // Return to dashboard and indicate a booking was created
        if (nav.mounted) nav.pop(true);
      }

      String _computeClientDisplay() {
        if (_selectedClient != null) return '${_selectedClient!.firstName} ${_selectedClient!.lastName}';
        if (widget.quote != null) return 'Client (from quote)';
        if (widget.existing != null) return 'Client ID: ${widget.existing!.clientId}';
        return 'No client selected';
      }

      String _computeQuoteDisplay() {
        Quote? q = widget.quote;
        if (q == null && _selectedQuoteId != null) {
          final matches = _clientQuotes.where((qq) => qq.id == _selectedQuoteId);
          if (matches.isNotEmpty) q = matches.first;
        }
        if (q != null) {
          final price = q.totalPrice.toStringAsFixed(2);
          return 'Quote #${q.id} — ${q.description} — R\$$price';
        }
        if (widget.existing != null && widget.existing!.quoteId != null) return 'Quote #${widget.existing!.quoteId}';
        return 'No quote selected';
      }

      String _twoDigits(int n) => n.toString().padLeft(2, '0');
      String _formatDateTime(DateTime dt) {
        const wk = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final day = wk[dt.weekday - 1];
        final month = mo[dt.month - 1];
        final hour = _twoDigits(dt.hour);
        final min = _twoDigits(dt.minute);
        return '$day, ${dt.day} $month • $hour:$min';
      }

      @override
      Widget build(BuildContext context) {
        final isEditing = widget.existing != null;
      // compute ids on demand where needed; controllers provide user-visible strings

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
                      if (!isEditing)
                        (widget.quote != null
                            ? ListTile(
                                contentPadding: UIStyles.tilePadding,
                                leading: const Icon(Icons.description_outlined),
                                title: Text('Quote #${widget.quote!.id}'),
                                subtitle: Text(widget.quote!.description),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Select client for this booking'),
                                  const SizedBox(height: 8),
                                  // Read-only field that opens a searchable client picker dialog
                                  InkWell(
                                    onTap: _openClientSearch,
                                    child: InputDecorator(
                                      decoration: const InputDecoration(labelText: 'Client', border: OutlineInputBorder()),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _selectedClient != null
                                                  ? '${_selectedClient!.firstName} ${_selectedClient!.lastName}'
                                                  : 'Tap to search clients',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.search),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_clientQuotes.isNotEmpty)
                                    DropdownButtonFormField<int>(
                                      items: _clientQuotes.map((q) => DropdownMenuItem(value: q.id, child: Text('Quote #${q.id} — ${q.description}'))).toList(),
                                      initialValue: _selectedQuoteId,
                                      onChanged: (v) {
                                        setState(() => _selectedQuoteId = v);
                                        _quoteDisplayController.text = _computeQuoteDisplay();
                                      },
                                      decoration: const InputDecoration(labelText: 'Quote (optional)', border: OutlineInputBorder()),
                                      isExpanded: true,
                                    ),
                                ],
                              ))
                      else
                        ListTile(
                          contentPadding: UIStyles.tilePadding,
                          leading: const Icon(Icons.edit_calendar_outlined),
                          title: Text('Booking #${widget.existing!.bookingId ?? ''}'),
                          subtitle: const Text('Edit booking details'),
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        enabled: false,
                        controller: _clientDisplayController,
                        decoration: const InputDecoration(
                          labelText: 'Client',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        enabled: false,
                        controller: _quoteDisplayController,
                        decoration: const InputDecoration(
                          labelText: 'Quote',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: UIStyles.outlineButton(context),
                        onPressed: _pickDateTime,
                        icon: const Icon(Icons.event),
                        label: Text(
                          _selectedDateTime == null
                              ? 'Select Date & Time'
                              : _formatDateTime(_selectedDateTime!),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _statusController,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => null,
                      ),
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
                        label: const Text('Save Booking'),
                      ),
              ],
            ),
          ),
        );
      }
    }

