import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/booking.dart';
import 'package:shutterbook/data/tables/booking_table.dart';
import 'package:shutterbook/data/tables/client_table.dart';
import 'package:shutterbook/data/tables/quote_table.dart';
import 'package:shutterbook/data/tables/inventory_table.dart';
import 'package:shutterbook/pages/bookings/create_booking.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/widgets/stat_grid.dart';
import 'package:shutterbook/theme/ui_styles.dart';
import 'package:shutterbook/pages/bookings/stats_page.dart';
import 'package:shutterbook/utils/formatters.dart';

class DashboardPage extends StatefulWidget {
  final void Function(int index)? onNavigateToTab;
  final bool embedded; // when true, return content only (no Scaffold)

  const DashboardPage({super.key, this.onNavigateToTab, this.embedded = false});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

// header delegate removed — use a single scrollable Column for simplicity

class _DashboardPageState extends State<DashboardPage> {
  // Dashboard no longer supports in-place calendar/list toggle; show concise overview only
  Client? _clientFromArgs;
  bool _showQuotesInMain = false;
  // quote-specific fields removed - Dashboard shows recent quotes via QuoteTable directly
  bool _argsProcessed = false;

  int _upcomingCount = 0;
  int _clientsCount = 0;
  int _quotesCount = 0;
  int _inventoryCount = 0;
  bool _statsLoading = true;
  late Future<List<dynamic>> _dashboardFuture;

  // navigation to create booking performed inline where needed

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsProcessed) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final maybeClient = args['client'];
      final view = args['view'];
      if (maybeClient is Client) {
        _clientFromArgs = maybeClient;
        if (view == 'quotes') {
          _showQuotesInMain = true;
        }
      }
    }
    _argsProcessed = true;
    _loadStats();
    _initDashboardFuture();
  }

  void _initDashboardFuture() {
    _dashboardFuture = Future.wait([
      BookingTable().getAllBookings(),
      QuoteTable().getAllQuotes(),
      ClientTable().getAllClients(),
    ]);
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final all = await BookingTable().getAllBookings();
      final now = DateTime.now();
      _upcomingCount = all.where((b) => b.bookingDate.isAfter(now)).length;
      _clientsCount = (await ClientTable().getAllClients()).length;
      _quotesCount = (await QuoteTable().getAllQuotes()).length;
      _inventoryCount = (await InventoryTable().getItemCount());
    } catch (_) {}
    if (!mounted) return;
    setState(() => _statsLoading = false);
  }

  Color _statusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'completed':
        return theme.colorScheme.secondary;
      case 'cancelled':
        return theme.colorScheme.error;
      case 'confirmed':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.primaryContainer;
    }
  }

  // client-scoped quote loading removed; dashboard shows recent quotes globally




  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget headerSection = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        elevation: UIStyles.cardElevation,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Builder(
              builder: (context) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Welcome back', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('Your Shutterbook Overview', style: theme.textTheme.bodyMedium),
                          ]),
                        ),
                        // tappable stats icon — opens the Stats screen
                        InkWell(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatsPage())),
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.bar_chart, size: 28, color: theme.colorScheme.onPrimaryContainer),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _statsLoading
                        ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))
                        : StatGrid(items: [
                            StatItem(label: 'Upcoming', value: _upcomingCount.toString(), icon: Icons.calendar_today),
                            StatItem(label: 'Clients', value: _clientsCount.toString(), icon: Icons.people),
                            StatItem(label: 'Quotes', value: _quotesCount.toString(), icon: Icons.request_quote),
                            StatItem(label: 'Items', value: _inventoryCount.toString(), icon: Icons.inventory),
                          ]),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    // main body content
    // Simplified dashboard: show stats + next 3 upcoming bookings + recent 3 quotes
    Widget bodyContent = FutureBuilder<List<dynamic>>(
      future: _dashboardFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }

        final data = snap.data ?? <dynamic>[];
        final bookings = (data.isNotEmpty ? (data[0] as List<Booking>) : <Booking>[])
            .where((b) => b.bookingDate.isAfter(DateTime.now()))
            .toList()
          ..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
        final quotes = data.length > 1 ? (data[1] as List<Quote>) : <Quote>[];
        final clients = data.length > 2 ? (data[2] as List<Client>) : <Client>[];

        final clientById = {for (var c in clients) (c.id ?? -1): c};

        String fmtDate(DateTime dt) {
          final d = dt.toLocal();
          final day = d.day.toString().padLeft(2, '0');
          final month = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month-1];
          final year = d.year;
          final hour = d.hour.toString().padLeft(2, '0');
          final minute = d.minute.toString().padLeft(2, '0');
          return '$day $month $year • $hour:$minute';
        }

        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 8),
          // Next bookings - show as responsive grid
          Text('Next bookings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (bookings.isEmpty)
            const Text('No upcoming bookings')
          else
            LayoutBuilder(builder: (context, constraints) {
              final cols = constraints.maxWidth >= 620 ? 2 : 1;
              final items = bookings.take(6).toList();
              // compute childAspectRatio based on available width and desired tile height
              final tileHeight = cols == 2 ? 84.0 : 76.0; // slightly taller for two columns
              final childAspectRatio = (constraints.maxWidth / cols) / tileHeight;
              return GridView.count(
                crossAxisCount: cols,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: childAspectRatio.clamp(1.6, 4.0),
                children: items.map((b) {
                  final when = b.bookingDate;
                  final client = clientById[b.clientId];
                  final clientLabel = client != null ? '${client.firstName} ${client.lastName}' : 'Client #${b.clientId}';
                  final initials = client != null && (client.firstName.isNotEmpty || client.lastName.isNotEmpty)
                      ? '${client.firstName.isNotEmpty ? client.firstName[0] : ''}${client.lastName.isNotEmpty ? client.lastName[0] : ''}'.toUpperCase()
                      : '#';
                  return Card(
                    margin: EdgeInsets.zero,
                    elevation: UIStyles.cardElevation,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateBookingPage(existing: b))).then((_) { if (mounted) setState(() {}); }),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(children: [
                          CircleAvatar(radius: 18, child: Text(initials, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                              Text(clientLabel, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(fmtDate(when), style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ]),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Builder(builder: (context) {
                              final bg = _statusColor(b.status, theme);
                              final fg = bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;
                              return Chip(
                                label: Text(b.status, style: theme.textTheme.bodySmall?.copyWith(color: fg, fontWeight: FontWeight.w600)),
                                backgroundColor: bg,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              );
                            }),
                          ),
                        ]),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),

          const SizedBox(height: 12),
          // Recent quotes - two-column grid
          Text('Recent quotes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (quotes.isEmpty)
            const Text('No quotes yet')
          else
            LayoutBuilder(builder: (context, constraints) {
              final cols = constraints.maxWidth >= 620 ? 2 : 1;
              final items = quotes.take(6).toList();
              final tileHeight = cols == 2 ? 84.0 : 76.0;
              final childAspectRatio = (constraints.maxWidth / cols) / tileHeight;
              return GridView.count(
                crossAxisCount: cols,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: childAspectRatio.clamp(1.6, 4.0),
                children: items.map((q) {
                  final client = clientById[q.clientId];
                  final clientLabel = client != null ? '${client.firstName} ${client.lastName}' : 'Client #${q.clientId}';
                  final initials = client != null && (client.firstName.isNotEmpty || client.lastName.isNotEmpty)
                      ? '${client.firstName.isNotEmpty ? client.firstName[0] : ''}${client.lastName.isNotEmpty ? client.lastName[0] : ''}'.toUpperCase()
                      : '#';
                              return Card(
                    margin: EdgeInsets.zero,
                    elevation: UIStyles.cardElevation,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: InkWell(
                      onTap: () => widget.onNavigateToTab?.call(3),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(children: [
                          CircleAvatar(radius: 18, child: Text(initials, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                              Text(clientLabel, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(children: [
                                Expanded(child: Text(q.description, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 8),
                                Chip(label: Text(formatRand(q.totalPrice), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimary)), backgroundColor: theme.colorScheme.primary, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0)),
                              ])
                            ]),
                          ),
                        ]),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),

          const SizedBox(height: 12),
          // Link to full sections
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => widget.onNavigateToTab?.call(1),
                icon: const Icon(Icons.calendar_today),
                label: const Text('Open Bookings'),
                style: UIStyles.outlineButton(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => widget.onNavigateToTab?.call(3),
                icon: const Icon(Icons.request_quote),
                label: const Text('Open Quotes'),
                style: UIStyles.outlineButton(context),
              ),
            ),
          ]),
        ]);
      },
    );

    Future<void> refreshAll() async {
      // reload stats and then rebuild to refresh bookings/quotes futures
      await _loadStats();
      // recreate dashboard future so FutureBuilder refires
      _initDashboardFuture();
      if (mounted) setState(() {});
    }

    final content = SafeArea(
      child: RefreshIndicator(
        onRefresh: refreshAll,
        // Use a scroll view with slivers for more robust layout and better spacing control.
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: headerSection),
            const SliverToBoxAdapter(child: Divider(height: 1)),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverToBoxAdapter(
                child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: bodyContent),
              ),
            ),
            // add bottom padding to avoid content being obscured by system bars / nav bars
            SliverPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16,
              ),
              sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
          ],
        ),
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      appBar: UIStyles.accentAppBar(
        context,
        _clientFromArgs != null
            ? Text('${_showQuotesInMain ? 'Quotes' : 'Bookings'} — ${_clientFromArgs!.firstName} ${_clientFromArgs!.lastName}')
            : const Text('Photography Bookings Dashboard'),
        0,
        actions: [
          if (_clientFromArgs != null)
            IconButton(
              tooltip: 'Clear client filter',
              onPressed: () {
                setState(() {
                  _clientFromArgs = null;
                  _showQuotesInMain = false;
                  _argsProcessed = false;
                });
              },
              icon: const Icon(Icons.clear),
            ),
        ],
      ),
      body: content,
    );
  }
}



 
