import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shutterbook/data/tables/booking_table.dart';
import 'package:shutterbook/data/tables/client_table.dart';
import 'package:shutterbook/data/tables/quote_table.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/models/booking.dart';
import 'package:shutterbook/theme/ui_styles.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

// Reusable status pie chart widget so it can be tested independently and keeps
// layout concerns isolated from the page state.
class StatusPieChart extends StatefulWidget {
  final Map<String, int> bookingsByStatus;

  const StatusPieChart({super.key, required this.bookingsByStatus});

  @override
  State<StatusPieChart> createState() => _StatusPieChartState();
}

class _StatusPieChartState extends State<StatusPieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.bookingsByStatus;
    if (data.isEmpty) return Center(child: Text('No status data', style: theme.textTheme.bodySmall));

    final entries = data.entries.toList();
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.error,
      theme.colorScheme.primaryContainer,
    ];

    final sections = List<PieChartSectionData>.generate(entries.length, (i) {
      final e = entries[i];
      final color = colors[i % colors.length];
      final touched = _touchedIndex == i;
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: color,
        radius: touched ? 48 : 36,
        showTitle: false,
      );
    });

    final legendCount = entries.length;
    final legendRows = (legendCount / 2).ceil();
    final legendHeight = (legendRows * 36.0).clamp(36.0, 160.0);

    // Legend implemented using a Wrap so items flow responsively. Each legend
    // item gets up to half the available width (on narrow screens this keeps
    // things readable) and the label is allowed to wrap up to two lines. This
    // avoids the GridView childAspectRatio issues that could clip text on
    // constrained widths.
    final legendGrid = LayoutBuilder(builder: (ctx, lgConstraints) {
      final avail = lgConstraints.maxWidth.isFinite ? lgConstraints.maxWidth : 300.0;
      final colWidth = (avail / 2) - 12.0; // give a little spacing allowance

      return SizedBox(
        // keep the same visual footprint as before but allow it to grow a bit
        // if needed; clamp to a reasonable max so cards don't become huge.
        height: legendHeight,
        child: Align(
          alignment: Alignment.topLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: List.generate(legendCount, (i) {
              final e = entries[i];
              final color = colors[i % colors.length];
              final label = '${e.key} — ${e.value}';
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: colWidth, minWidth: 80),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  CircleAvatar(backgroundColor: color, radius: 8),
                  const SizedBox(width: 8),
                  // Allow wrapping up to two lines so long labels don't get
                  // vertically clipped on small screens.
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              );
            }),
          ),
        ),
      );
    });

    return LayoutBuilder(builder: (context, constraints) {
      final maxAvailable = constraints.maxHeight.isFinite ? constraints.maxHeight : 260.0;
      final legendBase = legendHeight;
      final paddingAndSpacing = 24.0;
      final safety = 8.0;
      final chartHeight = (maxAvailable - legendBase - paddingAndSpacing - safety).clamp(60.0, maxAvailable - 36.0);

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              height: chartHeight,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 4,
                  centerSpaceRadius: 18,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (response == null || response.touchedSection == null) {
                        setState(() => _touchedIndex = null);
                        return;
                      }
                      setState(() => _touchedIndex = response.touchedSection!.touchedSectionIndex);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_touchedIndex != null && _touchedIndex! >= 0 && _touchedIndex! < entries.length)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                child: Text('${entries[_touchedIndex!].key}: ${entries[_touchedIndex!].value}', style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
              ),
            legendGrid,
          ]),
        ),
      );
    });
  }
}

class _StatsPageState extends State<StatsPage> {
  bool _loading = true;
  int _totalBookings = 0;
  int _upcoming = 0;
  int _clients = 0;
  int _quotesCount = 0;
  List<int> _last7DaysCounts = List.filled(7, 0);
  Map<String, int> _bookingsByStatus = {};
  double _totalRevenue = 0.0;
  List<double> _monthlyRevenue = [];
  List<MapEntry<Client, int>> _topClientsByBookings = [];
  List<Booking> _bookings = [];
  List<Quote> _quotes = [];

  // (deprecated) previously used for inline pie chart; replaced by StatusPieChart's internal state.
  // kept for now to avoid wider diff; can be removed in a follow-up cleanup.
  // int? _touchedPieIndex;
  // revenue source: bookings only (default) or all quotes
  bool _revenueFromAllQuotes = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _recomputeRevenue() {
    // recompute _totalRevenue and _monthlyRevenue depending on _revenueFromAllQuotes
    _totalRevenue = 0.0;
    final now = DateTime.now();
    final nowMonth = DateTime(now.year, now.month);
    final months = List.generate(6, (i) => DateTime(nowMonth.year, nowMonth.month - (5 - i)));
    final monthly = List<double>.filled(6, 0.0);

    if (_revenueFromAllQuotes) {
      // Sum all quotes for total revenue
      for (var q in _quotes) {
        _totalRevenue += q.totalPrice;
        final dt = q.createdAt != null ? DateTime(q.createdAt!.year, q.createdAt!.month) : null;
        if (dt != null) {
          for (var i = 0; i < months.length; i++) {
            if (dt.year == months[i].year && dt.month == months[i].month) monthly[i] += q.totalPrice;
          }
        }
      }
    } else {
      // revenue only from bookings (linked quotes)
      final quoteById = {for (var q in _quotes) (q.id ?? -1): q};
      for (var b in _bookings) {
        if (b.quoteId != null && quoteById.containsKey(b.quoteId)) {
          final q = quoteById[b.quoteId] as Quote;
          _totalRevenue += q.totalPrice;
          final dt = DateTime(b.bookingDate.year, b.bookingDate.month);
          for (var i = 0; i < months.length; i++) {
            if (dt.year == months[i].year && dt.month == months[i].month) monthly[i] += q.totalPrice;
          }
        }
      }
    }

    setState(() {
      _monthlyRevenue = monthly;
    });
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
  _bookings = await BookingTable().getAllBookings();
  final clients = await ClientTable().getAllClients();
  _quotes = await QuoteTable().getAllQuotes();

      // Yield to the event loop so the UI can render first (reduces startup jank).
      // The heavy accumulator work runs afterward — not a full isolate but helps avoid skipped frames.
      await Future<void>.delayed(Duration.zero);

      // reset accumulators
      _totalBookings = 0;
      _upcoming = 0;
      _bookingsByStatus = {};
      _totalRevenue = 0.0;
      _last7DaysCounts = List.filled(7, 0);

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));

  // map quotes for quick lookup
  final quoteById = {for (var q in _quotes) (q.id ?? -1): q};

      // bookings per client
      final Map<int, int> bookingsPerClient = {};

  for (var b in _bookings) {
        _totalBookings++;
        if (b.bookingDate.isAfter(now)) _upcoming++;

  final s = b.status.toLowerCase();
        if (s.isNotEmpty) _bookingsByStatus[s] = (_bookingsByStatus[s] ?? 0) + 1;

        final dayIndex = b.bookingDate.isBefore(start) ? -1 : b.bookingDate.difference(start).inDays.clamp(0, 6);
        if (dayIndex >= 0 && dayIndex < 7) _last7DaysCounts[dayIndex]++;

        bookingsPerClient[b.clientId] = (bookingsPerClient[b.clientId] ?? 0) + 1;

        if (b.quoteId != null && quoteById.containsKey(b.quoteId)) {
          final q = quoteById[b.quoteId] as Quote;
          _totalRevenue += q.totalPrice;
        }
      }

      // NOTE: don't finalize total revenue here to avoid double-counting.
      // Revenue will be computed by _recomputeRevenue() according to the selected source.

      // compute monthly revenue for last 6 months (based on booking date + linked quote)
      final nowMonth = DateTime(now.year, now.month);
      final months = List.generate(6, (i) => DateTime(nowMonth.year, nowMonth.month - (5 - i)));
      final monthly = List<double>.filled(6, 0.0);
      for (var b in _bookings) {
        if (b.quoteId != null && quoteById.containsKey(b.quoteId)) {
          final q = quoteById[b.quoteId] as Quote;
          final dt = DateTime(b.bookingDate.year, b.bookingDate.month);
          for (var i = 0; i < months.length; i++) {
            if (dt.year == months[i].year && dt.month == months[i].month) {
              monthly[i] += q.totalPrice;
            }
          }
        }
      }

      final clientsById = {for (var c in clients) (c.id ?? -1): c};
      final clientEntries = bookingsPerClient.entries
          .where((e) => clientsById.containsKey(e.key))
          .map((e) => MapEntry(clientsById[e.key]!, e.value))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        _clients = clients.length;
        _quotesCount = _quotes.length;
        _last7DaysCounts = _last7DaysCounts;
        _monthlyRevenue = monthly;
        _topClientsByBookings = clientEntries.take(5).toList();
      });

      // compute revenue according to current preference
      _recomputeRevenue();
    } catch (e) {
      // ignore
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: UIStyles.accentAppBar(context, const Text('Stats'), 1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
      child: _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Card(
                    elevation: UIStyles.cardElevation,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Use Expanded so the stat tiles share available width and avoid overflow on narrow screens
                          Expanded(child: _statTile(context, 'Bookings', _totalBookings.toString(), Icons.event_note)),
                          const SizedBox(width: 8),
                          Expanded(child: _statTile(context, 'Upcoming', _upcoming.toString(), Icons.calendar_today)),
                          const SizedBox(width: 8),
                          Expanded(child: _statTile(context, 'Clients', _clients.toString(), Icons.people)),
                          const SizedBox(width: 8),
                          Expanded(child: _statTile(context, 'Quotes', _quotesCount.toString(), Icons.request_quote)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Bookings last 7 days', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(height: 160, child: _buildBarChart(context)),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    // Allow the title to take available space so chips can size to their intrinsic width
                    Expanded(child: Text('Revenue (last 6 months)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                    // Keep the chip group to its intrinsic width to avoid forcing the Row to expand
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Source: '),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Bookings'),
                        selected: !_revenueFromAllQuotes,
                        onSelected: (v) {
                          if (v) {
                            _revenueFromAllQuotes = false;
                            _recomputeRevenue();
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('All quotes'),
                        selected: _revenueFromAllQuotes,
                        onSelected: (v) {
                          if (v) {
                            _revenueFromAllQuotes = true;
                            _recomputeRevenue();
                          }
                        },
                      ),
                    ])
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(height: 160, child: _buildRevenueChart(context)),
                    const SizedBox(height: 12),
                    // bookings by status pie chart
                    _buildStatusPieChart(context),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: Card(
                      elevation: UIStyles.cardElevation,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      // Make the Card's content scrollable so its contents don't force an overflow
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Quick insights', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('• Total bookings: $_totalBookings'),
                          Text('• Upcoming bookings: $_upcoming'),
                          Text('• Clients: $_clients'),
                          Text('• Quotes: $_quotesCount'),
                          Text('• Total revenue: ${_totalRevenue.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          Text('Top clients', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 8),
                          // Keep the list scrollable inside the card
                          _buildTopClientsList(),
                        ]),
                      ),
                    ),
                  ),
                ]),
                ),
        ),
      ),
    );
  }

  Widget _statTile(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(children: [
      CircleAvatar(backgroundColor: theme.colorScheme.primary, child: Icon(icon, color: theme.colorScheme.onPrimary)),
      const SizedBox(height: 8),
      Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, style: theme.textTheme.bodySmall),
    ]);
  }

  Widget _buildBarChart(BuildContext context) {
    final theme = Theme.of(context);
    final labels = List.generate(7, (i) {
      final dt = DateTime.now().subtract(Duration(days: 6 - i));
      return ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][dt.weekday % 7];
    });

    final maxVal = _last7DaysCounts.reduce((a, b) => a > b ? a : b);
    final scale = maxVal == 0 ? 1.0 : (maxVal.toDouble());

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final val = _last7DaysCounts[i];
          final heightFactor = scale == 0 ? 0.0 : (val / scale);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                AnimatedContainer(duration: const Duration(milliseconds: 400), height: 100 * heightFactor, width: double.infinity, decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 6),
                Text(labels[i], style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text('$val', style: theme.textTheme.bodySmall),
              ]),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context) {
    final theme = Theme.of(context);
    if (_monthlyRevenue.isEmpty) return Center(child: Text('No revenue data', style: theme.textTheme.bodySmall));

    final spots = List.generate(_monthlyRevenue.length, (i) => FlSpot(i.toDouble(), _monthlyRevenue[i]));
    final maxY = _monthlyRevenue.reduce((a, b) => a > b ? a : b);
    final formatter = NumberFormat.simpleCurrency(locale: Localizations.localeOf(context).toString());

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: LineChart(LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 60, getTitlesWidget: (v, meta) {
              final label = formatter.format(v);
              return Text(label, style: theme.textTheme.bodySmall);
            })),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) {
              final index = v.toInt();
              final dt = DateTime.now();
              final month = DateTime(dt.year, dt.month - (_monthlyRevenue.length - 1 - index));
              return Text('${month.month}/${month.year % 100}', style: theme.textTheme.bodySmall);
            })),
          ),
          minY: 0,
          maxY: maxY == 0 ? 1.0 : maxY,
          lineBarsData: [
            LineChartBarData(spots: spots, isCurved: true, color: theme.colorScheme.primary, barWidth: 3, dotData: FlDotData(show: true)),
          ],
        )),
      ),
    );
  }

  Widget _buildStatusPieChart(BuildContext context) {
    // Extracted to a reusable widget below to enable testing and better layout control.
    return StatusPieChart(bookingsByStatus: _bookingsByStatus);
  }

  Widget _buildTopClientsList() {
    if (_topClientsByBookings.isEmpty) return const Text('No clients yet');
    return Column(
      children: _topClientsByBookings.map((e) {
        final client = e.key;
        final initials = ((client.firstName.isNotEmpty ? client.firstName[0] : '') + (client.lastName.isNotEmpty ? client.lastName[0] : '')).toUpperCase();
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Text(initials.isNotEmpty ? initials : '?')),
          title: Text('${client.firstName} ${client.lastName}'),
          trailing: Text('${e.value} bookings'),
        );
      }).toList(),
    );
  }
}
