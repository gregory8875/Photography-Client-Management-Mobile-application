// Shutterbook — Bookings list page
// Displays a paginated list or calendar of bookings and provides
// entry points to create or edit bookings.
import 'dart:async';
// Shutterbook — Bookings list page
// Displays a paginated list or calendar of bookings and provides
// entry points to create or edit bookings.
import 'package:flutter/material.dart';
import 'package:shutterbook/theme/ui_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'booking_calendar_view.dart';
import '../../widgets/section_card.dart';
import '../../data/models/booking.dart';
import '../../data/models/client.dart';
import '../../data/models/quote.dart';
import '../../data/services/data_cache.dart';
import '../../data/tables/client_table.dart';
import '../../data/tables/quote_table.dart';
import 'create_booking.dart';

class BookingsPage extends StatefulWidget {
  final bool embedded;
  final Client? initialClient;
  const BookingsPage({super.key, this.embedded = false, this.initialClient});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  // 0 = calendar, 1 = list
  int _view = 0;
  int _prevView = 0;
  Client? _clientFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;
  bool _restoring = false;
  static const String _kLastClientIdKey = 'bookings_last_client_id';
  static const String _kLastSearchKey = 'bookings_last_search';

  @override
  void initState() {
    super.initState();
    // If an initial client was passed explicitly, prefer that (e.g., programmatic navigation)
    if (widget.initialClient != null) {
      _clientFilter = widget.initialClient;
      _prevView = _view;
      _view = 1; // show list when opened for a client
    }

    // Restore persisted client/search if no explicit initial client provided
    _restoreState();

    // Debounced listener to avoid filtering on every keystroke
    _searchController.addListener(_onSearchTextChanged);
  }

  /// Open the Create Booking flow from the embedded bookings page.
  /// If a [quote] is provided, the Create flow will preselect it.
  Future<void> openCreateBooking({Quote? quote}) async {
    final nav = Navigator.of(context);
    await nav.push<bool>(MaterialPageRoute(builder: (_) => CreateBookingPage(quote: quote)));
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    _debounceTimer?.cancel();
    // If we're restoring initial values, skip handling to avoid persisting while restoring
    if (_restoring) return;
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final txt = _searchController.text.trim();
      setState(() {
        _searchQuery = txt;
      });
      final prefs = await SharedPreferences.getInstance();
      if (txt.isEmpty) {
        await prefs.remove(_kLastSearchKey);
      } else {
        await prefs.setString(_kLastSearchKey, txt);
      }
    });
  }

  Future<void> _restoreState() async {
    _restoring = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (widget.initialClient == null) {
        final clientId = prefs.getInt(_kLastClientIdKey);
          if (clientId != null) {
          try {
            final c = await ClientTable().getClientById(clientId);
            if (c != null) {
              setState(() {
                _clientFilter = c;
                  _prevView = _view;
                  _view = 1;
              });
            }
          } catch (_) {}
        }
      }
      final lastSearch = prefs.getString(_kLastSearchKey) ?? '';
      if (lastSearch.isNotEmpty) {
        _searchController.text = lastSearch;
        // ensure the debounced handler picks it up after restoring
        setState(() {
          _searchQuery = lastSearch;
        });
      }
    } finally {
      _restoring = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: LayoutBuilder(builder: (context, constraints) {
  // Allocate up to 40% of the width (max 240) for the toggle controls on the right
  final maxToggleWidth = (constraints.maxWidth * 0.4).clamp(120.0, 240.0);
        final gap = 6.0; // space between two buttons
        final buttonWidth = (maxToggleWidth - gap) / 2;
        final btnConstraints = BoxConstraints(minWidth: buttonWidth, minHeight: 36);

  final viewLabel = _view == 0 ? 'Calendar' : 'List';
        // Prevent label width jumps when switching by giving the label a stable max width
        final labelMaxWidth = (constraints.maxWidth - maxToggleWidth - 32).clamp(80.0, constraints.maxWidth * 0.6);
        return Row(children: [
          SizedBox(
            width: labelMaxWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Builder(builder: (context) {
                final reduceMotion = MediaQuery.of(context).accessibleNavigation;
                final duration = reduceMotion ? Duration.zero : const Duration(milliseconds: 220);
                final direction = _view >= _prevView ? 1.0 : -1.0;
                final offsetMag = reduceMotion ? 0.0 : 0.04;
                return AnimatedSwitcher(
                  duration: duration,
                  transitionBuilder: (child, anim) {
                    // Simple direction-aware slide + fade tuned for smoothness.
                    final offsetAnim = Tween<Offset>(begin: Offset(offsetMag * direction, 0), end: Offset.zero)
                        .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
                    return SlideTransition(position: offsetAnim, child: FadeTransition(opacity: anim, child: child));
                  },
                  child: Text(viewLabel, key: ValueKey(viewLabel), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          const Spacer(),
          SizedBox(
            width: maxToggleWidth,
            child: ToggleButtons(
              isSelected: [_view == 0, _view == 1],
              onPressed: (i) => setState(() {
                _prevView = _view;
                _view = i;
              }),
              borderRadius: BorderRadius.circular(8),
              constraints: btnConstraints,
              color: Theme.of(context).colorScheme.onSurface,
              selectedColor: Theme.of(context).colorScheme.onPrimary,
              fillColor: Theme.of(context).colorScheme.primary,
              borderColor: Theme.of(context).dividerColor,
              selectedBorderColor: Theme.of(context).colorScheme.primary,
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.calendar_today)),
                Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.list)),
              ],
            ),
          ),
        ]);
      }),
    );

    final bodyContent = AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(children: <Widget>[...previousChildren, if (currentChild != null) currentChild]);
        },
        transitionBuilder: (child, anim) {
          final offsetAnim = Tween<Offset>(begin: const Offset(0.12, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
          return FadeTransition(opacity: anim, child: SlideTransition(position: offsetAnim, child: child));
        },
        child: SectionCard(
          key: ValueKey<int>(_view),
          child: _view == 0
              ? const BookingCalendarView()
              : BookingListView(
                  searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
                  clientId: _clientFilter?.id,
                ),
        ),
      ),
    );

    final searchBar = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOut, 
              switchOutCurve: Curves.easeIn,
              child: _clientFilter != null
                  ? Padding(
                      key: ValueKey('client-${_clientFilter!.id}'),
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(children: [
                        Expanded(child: Text('Filtering by client', style: Theme.of(context).textTheme.bodySmall)),
                        InputChip(
                          label: Text('${_clientFilter!.firstName} ${_clientFilter!.lastName}'),
                          onDeleted: () async {
                            setState(() {
                              _clientFilter = null;
                              _searchController.clear();
                              _searchQuery = '';
                            });
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove(_kLastClientIdKey);
                            await prefs.remove(_kLastSearchKey);
                          },
                        ),
                      ]),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _clientFilter != null ? 'Search bookings for ${_clientFilter!.firstName} ${_clientFilter!.lastName}' : 'Search bookings (name, status, date)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
          ),
        ],
      ),
    );

    final bodyChildren = <Widget>[header, const SizedBox(height: 8)];
    // show search only on list view
    if (_view == 1) {
      bodyChildren.addAll([searchBar, const SizedBox(height: 8)]);
    }
    bodyChildren.add(Expanded(child: bodyContent));

    final body = Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: Column(children: bodyChildren));

    return widget.embedded
        ? Column(children: [header, const SizedBox(height: 8), if (_view == 1) searchBar, const SizedBox(height: 8), Expanded(child: bodyContent)])
        : Scaffold(
            appBar: UIStyles.accentAppBar(
              context,
              const Text('Bookings'),
              1,
              actions: [
                IconButton(
                  tooltip: 'Dashboard',
                  icon: const Icon(Icons.dashboard),
                  onPressed: () => Navigator.pushNamed(context, '/dashboard'),
                ),
              ],
            ),
            body: body,
          );
  }

  /// Set the active client filter, switch to list view and optionally prefill the search
  void focusOnClient(Client client, {String? query}) {
    setState(() {
      _clientFilter = client;
      _prevView = _view;
      _view = 1;
      _searchController.text = query ?? '';
      _searchQuery = _searchController.text.trim();
    });
    // persist selection
    SharedPreferences.getInstance().then((prefs) async {
      await prefs.setInt(_kLastClientIdKey, client.id ?? -1);
      if (_searchQuery.isNotEmpty) await prefs.setString(_kLastSearchKey, _searchQuery);
    });
  }
}

class BookingListView extends StatefulWidget {
  final String? searchQuery;
  final int? clientId;
  const BookingListView({super.key, this.searchQuery, this.clientId});

  @override
  State<BookingListView> createState() => _BookingListViewState();
}

class _BookingListViewState extends State<BookingListView> {
  final QuoteTable _quoteTable = QuoteTable();

  late Future<List<Booking>> _bookingsFuture;
  late Future<List<Client>> _clientsFuture;
  late Future<List<Quote>> _quotesFuture;

  @override
  void initState() {
    super.initState();
    _bookingsFuture = DataCache.instance.getBookings();
    _clientsFuture = DataCache.instance.getClients();
    _quotesFuture = _quoteTable.getAllQuotes();
  }

  String _fmt(DateTime d) {
    final dt = d.toLocal();
    final day = dt.day.toString().padLeft(2, '0');
    final month = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][dt.month-1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_bookingsFuture, _clientsFuture, _quotesFuture]),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        final data = snap.data ?? <dynamic>[];
  final bookings = data.isNotEmpty ? (data[0] as List<Booking>) : <Booking>[];
  final clients = data.length > 1 ? (data[1] as List<Client>) : <Client>[];
  final widgetSearch = widget.searchQuery?.toLowerCase();
  final widgetClientId = widget.clientId;
  final clientById = {for (var c in clients) (c.id ?? -1): c};
  // quotes are available in `quotes` if needed later


        // Apply client filter and search filter if provided
        var filtered = bookings;
        if (widgetClientId != null) {
          filtered = filtered.where((b) => b.clientId == widgetClientId).toList();
        }
        if (widgetSearch != null && widgetSearch.isNotEmpty) {
          filtered = filtered.where((b) {
            final client = clients.firstWhere((c) => c.id == b.clientId, orElse: () => Client(id: -1, firstName: '', lastName: '', email: '', phone: ''));
            final clientName = '${client.firstName} ${client.lastName}'.toLowerCase();
            final status = b.status.toLowerCase();
            final dateStr = _fmt(b.bookingDate).toLowerCase();
            return clientName.contains(widgetSearch) || status.contains(widgetSearch) || dateStr.contains(widgetSearch) || '${b.bookingId}'.contains(widgetSearch);
          }).toList();
        }

        if (filtered.isEmpty) return const Center(child: Text('No bookings'));

        filtered.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final b = filtered[index];
            final client = clientById[b.clientId];
            final title = client != null ? '${client.firstName} ${client.lastName}' : 'Client #${b.clientId}';
            final subtitle = '${_fmt(b.bookingDate)} • ${b.status}';
            final initials = client != null && (client.firstName.isNotEmpty || client.lastName.isNotEmpty)
                ? '${client.firstName.isNotEmpty ? client.firstName[0] : ''}${client.lastName.isNotEmpty ? client.lastName[0] : ''}'.toUpperCase()
                : '#';

            return SectionCard(
              child: ListTile(
                contentPadding: UIStyles.tilePadding,
                leading: CircleAvatar(child: Text(initials, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold))),
                title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
                trailing: IconButton(icon: const Icon(Icons.open_in_new), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateBookingPage(existing: b))).then((_) { if (mounted) setState(() {}); })),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateBookingPage(existing: b))).then((_) { if (mounted) setState(() {}); }),
              ),
            );
          },
        );
      },
    );
  }
}
