// Shutterbook — booking_calendar_view.dart
// ignore_for_file: use_build_context_synchronously
// A compact calendar view used in the bookings section to visualise
// upcoming sessions. It's intentionally small and focused on display logic.
import 'package:flutter/material.dart';
import 'package:shutterbook/theme/ui_styles.dart';
import 'package:shutterbook/data/models/booking.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/tables/booking_table.dart';
import 'package:shutterbook/data/tables/client_table.dart';
import 'package:shutterbook/data/services/data_cache.dart';
import 'package:shutterbook/data/tables/quote_table.dart';

class BookingCalendarView extends StatefulWidget {
  const BookingCalendarView({super.key});

  @override
  State<BookingCalendarView> createState() => _BookingCalendarViewState();
}

class _BookingCalendarViewState extends State<BookingCalendarView> {
  final bookingTable = BookingTable();
  final quoteTable = QuoteTable();
  // clientTable retained for writes; reads should use DataCache for better perf
  final clientTable = ClientTable();

  List<Booking> bookings = [];
  List<Client> allClients = [];
  Map<String, Client> clientByEmail = {};

  late DateTime weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    weekStart = now.subtract(Duration(days: now.weekday - 1));
  _loadBookings();
  _loadClients();
  }

  @override
  void dispose() {
    // Space for later timers
    super.dispose();
  }

Future<void> _loadBookings() async {
  try {
    final data = await DataCache.instance.getBookings();
    if (!mounted) return;
    setState(() {
      bookings = data;
    });
  } catch (_) {}
}

Future<void> _loadClients() async {
  try {
    final data = await DataCache.instance.getClients();
    final map = <String, Client>{};
    for (final c in data) {
      if (c.email.isNotEmpty) map[c.email] = c;
    }
    if (!mounted) return;
    setState(() {
      allClients = data;
      clientByEmail = map;
    });
  } catch (_) {}
}

  // Determine a background color for a booking status using the current theme
  Color getStatusColor(BuildContext context, String status) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    switch (status.toLowerCase()) {
      case 'scheduled':
        // Use primaryContainer for scheduled to adapt to dark/light themes
        return cs.primaryContainer;
      case 'completed':
        return cs.secondaryContainer;
      case 'cancelled':
        return cs.errorContainer;
      default:
        return cs.surfaceContainerHighest;
    }
  }
  Booking? getBookingForSlot(DateTime slot) {
    try {
      return bookings.firstWhere(
        (b) =>
            b.bookingDate.year == slot.year &&
            b.bookingDate.month == slot.month &&
            b.bookingDate.day == slot.day &&
            b.bookingDate.hour == slot.hour,
      );
    } catch (_) {
      return null;
    }
  }

  Client? getClientForBooking(Booking booking) {
    try {
      return allClients.firstWhere((c) => c.id == booking.clientId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _editBooking(DateTime slot, [Booking? existing]) async {
    Client? selectedClient;
    int? selectedQuoteId = existing?.quoteId;
    List<Quote> clientQuotes = [];
    String status = existing?.status ?? '';

    if (existing != null) {
      if (allClients.isNotEmpty) {
        selectedClient = allClients.firstWhere(
          (c) => c.id == existing.clientId,
          orElse: () => allClients.first,
        );
        try {
          clientQuotes = await quoteTable.getQuotesByClient(selectedClient.id!);
          if (clientQuotes.isNotEmpty &&
              (selectedQuoteId == null ||
                  !clientQuotes.any((q) => q.id == selectedQuoteId))) {
            selectedQuoteId = clientQuotes.first.id;
          }
        } catch (e) {
          clientQuotes = [];
        }
      } else {
        selectedClient = null;
      }
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final NavigatorState dialogNavigator = Navigator.of(context);
          final ScaffoldMessengerState dialogMessenger = ScaffoldMessenger.of(
            context,
          );
          return AlertDialog(
            title: Text(existing == null ? 'New Booking' : 'Edit Booking'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
Autocomplete<String>(
  initialValue: existing != null && selectedClient != null
      ? TextEditingValue(
          text:
              '${selectedClient!.firstName} ${selectedClient!.lastName} (${selectedClient!.email})',
        )
      : const TextEditingValue(),
  optionsBuilder: (TextEditingValue textEditingValue) {
    final query = textEditingValue.text.toLowerCase();
    if (query.isEmpty) return const Iterable<String>.empty();
    return allClients.where((c) {
      final full = '${c.firstName} ${c.lastName}'.toLowerCase();
      return c.firstName.toLowerCase().contains(query) ||
          c.lastName.toLowerCase().contains(query) ||
          full.contains(query) ||
          c.email.toLowerCase().contains(query);
    }).map((c) => '${c.firstName} ${c.lastName} (${c.email})');
  },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Client name or email',
                          prefixIcon: Icon(Icons.search),
                        ),
                      );
                    },
                    onSelected: (String selection) async {
                      final start = selection.lastIndexOf('(');
                      final end = selection.lastIndexOf(')');
                      String? email;
                      if (start != -1 && end != -1 && end > start) {
                        email = selection.substring(start + 1, end);
                      }

                      Client? client;
                      if (email != null) client = clientByEmail[email];

                      if (client == null) {
                        for (final c in allClients) {
                          final display =
                              '${c.firstName} ${c.lastName} (${c.email})';
                          if (display == selection) {
                            client = c;
                            break;
                          }
                        }
                      }

                      if (client == null) {
                        dialogMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Selected client not found'),
                          ),
                        );
                        return;
                      }

                      try {
                        if (client.id == null) {
                          setStateDialog(() {
                            selectedClient = client;
                            clientQuotes = [];
                            selectedQuoteId = null;
                          });
                          dialogMessenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Selected client is not saved (no id)',
                              ),
                            ),
                          );
                          return;
                        }
                        final quotes = await quoteTable.getQuotesByClient(
                          client.id!,
                        );
                        setStateDialog(() {
                          selectedClient = client;
                          clientQuotes = quotes;
                          selectedQuoteId = clientQuotes.isNotEmpty
                              ? clientQuotes.first.id
                              : null;
                        });
                      } catch (e) {
                        setStateDialog(() {
                          selectedClient = client;
                          clientQuotes = [];
                          selectedQuoteId = null;
                        });
                        dialogMessenger.showSnackBar(
                          SnackBar(content: Text('Failed loading quotes: $e')),
                        );
                      }
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      final opts = options.toList();
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: opts.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String display = opts[index];
                                final emailStart = display.lastIndexOf('(');
                                final namePart = emailStart > 0
                                    ? display.substring(0, emailStart).trim()
                                    : display;
                                final emailPart =
                                    (emailStart > 0 && display.endsWith(')'))
                                        ? display.substring(
                                            emailStart + 1,
                                            display.length - 1,
                                          )
                                        : '';
                                return ListTile(
                                  contentPadding: UIStyles.tilePadding,
                                  title: Text(namePart),
                                  subtitle: emailPart.isNotEmpty
                                      ? Text(emailPart)
                                      : null,
                                  onTap: () => onSelected(display),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: selectedQuoteId,
                    items: clientQuotes
                        .map(
                          (q) => DropdownMenuItem<int>(
                            value: q.id!,
                            child: Text(q.description),
                          ),
                        )
                        .toList(),
                    onChanged: clientQuotes.isEmpty
                        ? null
                        : (val) {
                            setStateDialog(() {
                              selectedQuoteId = val;
                            });
                          },
                    decoration: const InputDecoration(labelText: 'Quote'),
                    hint: const Text('Select Quote'),
                    isExpanded: true,
                    disabledHint: const Text('Select a client first'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: status.isEmpty ? 'Scheduled' : status,
                    items: const [
                      DropdownMenuItem(
                        value: 'Scheduled',
                        child: Text('Scheduled'),
                      ),
                      DropdownMenuItem(
                        value: 'Completed',
                        child: Text('Completed'),
                      ),
                      DropdownMenuItem(
                        value: 'Cancelled',
                        child: Text('Cancelled'),
                      ),
                    ],
                    onChanged: (val) {
                      setStateDialog(() {
                        status = val ?? 'Scheduled';
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Status'),
                    isExpanded: true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  dialogNavigator.pop();
                },
                child: const Text('Cancel'),
              ),
                  if (existing != null)
                    TextButton(
                      onPressed: () async {
                        // Use the captured NavigatorState (dialogNavigator) for
                        // subsequent dialogs. It provides a stable context while
                        // we await and lets us check `mounted` before performing
                        // any stateful operations.
                        final confirm = await showDialog<bool>(
                          context: dialogNavigator.context,
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
                        if (confirm != true) return;

                        final nav = dialogNavigator;
                        await bookingTable.deleteBooking(existing.bookingId!);
                        // Clear shared cache so lists refresh elsewhere
                        DataCache.instance.clearBookings();
                        if (nav.mounted) nav.pop();
                        if (!mounted) return;
                        _loadBookings();
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
              TextButton(
                onPressed: () async {
                  if (selectedClient == null) {
                    dialogMessenger.showSnackBar(
                      const SnackBar(content: Text('Please select a client.')),
                    );
                    return;
                  }
                  if (selectedQuoteId == null) {
                    dialogMessenger.showSnackBar(
                      const SnackBar(
                        content:
                            Text('Please select a quote for this client.'),
                      ),
                    );
                    return;
                  }

                  final nav = dialogNavigator;
                  // Double-booking check for this hour slot
                  final conflicts = await bookingTable.findHourConflicts(
                    slot,
                    excludeBookingId: existing?.bookingId,
                  );
                  if (conflicts.isNotEmpty) {
                    // Prompt using the stable dialogNavigator context
                    final proceed = await showDialog<bool>(
                          context: dialogNavigator.context,
                          builder: (innerCtx) => AlertDialog(
                            title: const Text('Possible double booking'),
                            content: Text(
                              'There is already ${conflicts.length} booking(s) in this time slot (hour).\n\nYou can edit the time or proceed and allow a double booking.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(innerCtx).pop(false),
                                child: const Text('Edit time'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(innerCtx).pop(true),
                                child: const Text('Proceed'),
                              ),
                            ],
                          ),
                        ) ?? false;
                    if (!proceed) return;
                  }
                  if (existing != null) {
                    Booking updated = Booking(
                      bookingId: existing.bookingId,
                      quoteId: selectedQuoteId!,
                      clientId: selectedClient!.id!,
                      bookingDate: slot,
                      status: status.isEmpty ? "Scheduled" : status,
                      createdAt: existing.createdAt,
                    );
                    await bookingTable.updateBooking(updated);
                    DataCache.instance.clearBookings();
                  } else {
                    Booking newBooking = Booking(
                      quoteId: selectedQuoteId!,
                      clientId: selectedClient!.id!,
                      bookingDate: slot,
                      status: status.isEmpty ? "Scheduled" : status,
                    );
                    await bookingTable.insertBooking(newBooking);
                    DataCache.instance.clearBookings();
                  }

                  if (nav.mounted) nav.pop();
                  if (!mounted) return;
                  _loadBookings();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _previousWeek() {
    setState(() {
      weekStart = weekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      weekStart = weekStart.add(const Duration(days: 7));
    });
  }

  String getWeekdayName(DateTime date) {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final hours = List.generate(10, (i) => 8 + i);
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    const double timeColumnWidth = 60;
    const double whiteSpaceWidth = 40;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isPhone = constraints.maxWidth < 480;
        final double timeCol = isPhone ? 48 : timeColumnWidth;
        final double whiteCol = isPhone ? 24 : whiteSpaceWidth;
        const double minBlock = 40;

        final double fitBlock =
            (constraints.maxWidth - timeCol - whiteCol) / 7.0;
        final bool needsHScroll = fitBlock < minBlock;
        final double blockW =
            needsHScroll ? minBlock : fitBlock.floorToDouble();
        final double contentW = timeCol + whiteCol + (blockW * 7);

        Widget buildDateRow() {
          final row = Row(
            children: [
              SizedBox(
                width: timeCol,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _previousWeek,
                  tooltip: 'Previous Week',
                ),
              ),
              for (int i = 0; i < days.length; i++)
                SizedBox(
                  width: blockW,
                  child: Center(
                    child: Text(
                      "${days[i].day.toString().padLeft(2, '0')}/${days[i].month.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              SizedBox(
                width: whiteCol,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _nextWeek,
                  tooltip: 'Next Week',
                ),
              ),
            ],
          );
          if (needsHScroll) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: contentW, child: row),
            );
          }
          return row;
        }

        Widget buildDaysRow() {
          final row = Row(
            children: [
              SizedBox(width: timeCol),
              for (final d in days)
                SizedBox(
                  width: blockW,
                  child: Center(
                    child: Text(
                      getWeekdayName(d),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color,
                      ),
                    ),
                  ),
                ),
              SizedBox(width: whiteCol),
            ],
          );
          if (needsHScroll) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: contentW, child: row),
            );
          }
          return row;
        }

        Widget buildHourRow(int hour) {
          final row = Row(
            children: [
              SizedBox(
                width: timeCol,
                child: Text(
                  "$hour:00",
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              for (final d in days)
                SizedBox(
                  width: blockW,
                  child: GestureDetector(
                    onTap: () {
                      final slot = DateTime(d.year, d.month, d.day, hour);
                      final booking = getBookingForSlot(slot);
                      _editBooking(slot, booking);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      height: 50,
                      decoration: BoxDecoration(
                        color: (() {
                          final slot = DateTime(d.year, d.month, d.day, hour);
                          final booking = getBookingForSlot(slot);
                          if (booking != null) {
                            return getStatusColor(context, booking.status);
                          }
                          return Theme.of(context).colorScheme.surfaceContainerHighest;
                        })(),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Theme.of(context).dividerColor.withAlpha((0.6 * 255).round())),
                      ),
                      child: Builder(
                        builder: (context) {
                          final slot = DateTime(d.year, d.month, d.day, hour);
                          final booking = getBookingForSlot(slot);
                          if (booking != null) {
                            final client = getClientForBooking(booking);
                            if (client != null) {
                              // pick a readable foreground color based on background
                              final bg = getStatusColor(context, booking.status);
                              final fg = bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;
                              return Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        client.firstName,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          color: fg,
                                        ),
                                      ),
                                      Text(
                                        client.lastName,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 9, color: fg),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ),
              SizedBox(width: whiteCol),
            ],
          );
          if (needsHScroll) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: contentW, child: row),
            );
          }
          return row;
        }

        return Column(
          children: [
            buildDateRow(),
            buildDaysRow(),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: hours.length,
                itemBuilder: (_, row) {
                  final hour = hours[row];
                  return buildHourRow(hour);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
