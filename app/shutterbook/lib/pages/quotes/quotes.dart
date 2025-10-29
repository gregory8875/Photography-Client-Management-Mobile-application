// Shutterbook — Quotes list
// Shows a list of quotes and provides access to create/manage flows. Keep
// view-only list logic here and delegate editing to dedicated screens.
import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/models/client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/quote.dart';
import '../../utils/formatters.dart';
import '../../data/tables/quote_table.dart';
import '../../data/tables/client_table.dart';
import '../../data/services/data_cache.dart';
import '../../widgets/section_card.dart';
import 'package:shutterbook/theme/ui_styles.dart';
import '../bookings/create_booking.dart';
import '../../widgets/client_search_dialog.dart';
import 'package_picker/package_picker/package_picker_screen.dart';
import '../../data/models/package.dart';
import 'overview/quote_overview_screen.dart';
import 'manage/manage_quote_screen.dart';

class QuotePage extends StatefulWidget {
  final bool embedded;
  const QuotePage({super.key, this.embedded = false});

  @override
  State<QuotePage> createState() => _QuotePageState();
}

class _QuotePageState extends State<QuotePage> {
  Client? _client;
  String _clientSearch = '';
  final TextEditingController _clientSearchController = TextEditingController();
  bool _loading = false;
  List<Quote> _quotes = [];
  // key pointing to the embedded QuoteList so we can trigger reloads
  final GlobalKey<_QuoteListState> _quoteListKey = GlobalKey<_QuoteListState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Client) {
      // Load quotes for this client
      _client = args;
      _loadQuotesForClient();
    }
  }

  Future<void> _loadQuotesForClient() async {
    if (_client == null || _client!.id == null) return;
    setState(() {
      _loading = true;
    });
    final data = await QuoteTable().getQuotesByClient(_client!.id!);
    if (!mounted) return;
    setState(() {
      _quotes = data;
      _loading = false;
    });
  }

  static const String _kLastClientIdKey = 'quotes_last_client_id';
  static const String _kLastSearchKey = 'quotes_last_search';

  /// Refresh the page data. Called by parent (e.g. dashboard) when an external
  /// action (like creating a quote) occurred and the list should reload.
  Future<void> refresh() async {
    if (_client != null) {
      await _loadQuotesForClient();
    } else {
      final s = _quoteListKey.currentState;
      if (s != null) await s.load();
    }
  }

  /// Focus this page on a specific client and load that client's quotes.
  Future<void> focusOnClient(Client client) async {
    _client = client;
    // persist selection
    SharedPreferences.getInstance().then((prefs) async {
      await prefs.setInt(_kLastClientIdKey, client.id ?? -1);
    });
    await _loadQuotesForClient();
  }

  @override
  void initState() {
    super.initState();
    _restoreState();
    _clientSearchController.addListener(() {
      final v = _clientSearchController.text.trim();
      if (v != _clientSearch) setState(() => _clientSearch = v);
    });
  }

  /// Start the guided Create Quote flow when the page is embedded.
  /// Mirrors the non-embedded FAB behavior so dashboard can request it.
  Future<void> startCreateQuoteFlow() async {
    final nav = Navigator.of(context);
    final client = await showDialog<Client?>(context: context, builder: (_) => const ClientSearchDialog());
    if (!mounted) return;
    if (client == null) return;
    final packages = await nav.push<dynamic>(
      MaterialPageRoute(builder: (_) => PackagePickerScreen(client: client)),
    );
    if (!mounted) return;
    if (packages == null) return;
    double total = 0.0;
    if (packages is Map) {
      for (final entry in packages.entries) {
        final key = entry.key;
        final val = entry.value;
        double price = 0.0;
        if (key is Package) {
          price = key.price;
        } else if (key is Map && key['price'] != null) {
          price = (key['price'] as num).toDouble();
        }
        final int qty = val is int ? val : int.tryParse(val.toString()) ?? 0;
        total += price * qty;
      }
    }
    final saved = await nav.push<bool?>(
      MaterialPageRoute(
        builder: (_) => QuoteOverviewScreen(client: client, total: total, packages: packages),
      ),
    );
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _restoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastClientId = prefs.getInt(_kLastClientIdKey);
      final lastSearch = prefs.getString(_kLastSearchKey) ?? '';
      if (lastClientId != null && lastClientId > 0) {
        try {
          final c = await ClientTable().getClientById(lastClientId);
          if (c != null) {
            setState(() {
              _client = c;
            });
            await _loadQuotesForClient();
          }
        } catch (_) {}
      }
      if (lastSearch.isNotEmpty) {
        _clientSearchController.text = lastSearch;
        setState(() => _clientSearch = lastSearch);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _clientSearchController.removeListener(() {});
    _clientSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If focused on a client, expose a small search bar and chip to clear the filter
    final clientBody = _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 260),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: _client != null
                            ? Padding(
                                key: ValueKey('client-${_client!.id}'),
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(children: [
                                  Expanded(child: Text('Filtering by client', style: Theme.of(context).textTheme.bodySmall)),
                                  InputChip(
                                    label: Text('${_client!.firstName} ${_client!.lastName}'),
                                    onDeleted: () async {
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.remove(_kLastClientIdKey);
                                      await prefs.remove(_kLastSearchKey);
                                      setState(() {
                                        _client = null;
                                        _quotes = [];
                                      });
                                    },
                                  ),
                                ]),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    TextField(
                      controller: _clientSearchController,
                      decoration: InputDecoration(
                        hintText: _client != null ? 'Search quotes for ${_client!.firstName} ${_client!.lastName}' : 'Search quotes',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _clientSearch.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _clientSearchController.clear())
                            : null,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                      onChanged: (v) {
                        setState(() => _clientSearch = v.trim());
                        // persist search
                        SharedPreferences.getInstance().then((prefs) async {
                          if (v.trim().isEmpty) {
                            await prefs.remove(_kLastSearchKey);
                          } else {
                            await prefs.setString(_kLastSearchKey, v.trim());
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _quotes.isEmpty
                    ? const Center(child: Text('No quotes for this client'))
          : ListView.separated(
            itemCount: _quotes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
                          final q = _quotes[index];
                          final title = 'Quote #${q.id}';
                          final subtitle = 'Total: ${formatRand(q.totalPrice)} • ${q.createdAt ?? ''}';
                          // apply client search filter if present
                          if (_clientSearch.isNotEmpty) {
                            final s = _clientSearch.toLowerCase();
                            final joined = '${q.description} ${q.id} ${q.totalPrice}'.toLowerCase();
                            if (!joined.contains(s)) return const SizedBox.shrink();
                          }
                            return SectionCard(
                                child: ListTile(
                                  contentPadding: UIStyles.tilePadding,
                                leading: const Icon(Icons.description_outlined),
                                title: Text(title),
                                subtitle: Text(
                                  '${q.description}\n$subtitle',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  // Open manage quote screen for that quote
                                  Navigator.pushNamed(
                                    context,
                                    '/quotes/manage',
                                    arguments: q,
                                  );
                                },
                              ),
                            );
                        },
                      ),
              ),
            ],
          );

    if (_client != null) {
      return widget.embedded
          ? clientBody
          : Scaffold(
              appBar: UIStyles.accentAppBar(context, Text('Quotes — ${_client!.firstName} ${_client!.lastName}'), 3),
              body: clientBody,
            );
    }

    // Default non-client view — show a list of quotes with actions
    return widget.embedded
      ? QuoteList(key: _quoteListKey)
    : Scaffold(
            appBar: UIStyles.accentAppBar(context, const Text('Quotes'), 3),
            body: const QuoteList(),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                // Start guided create flow: pick client -> package -> overview
                final nav = Navigator.of(context);
                final client = await showDialog<Client?>(context: context, builder: (_) => const ClientSearchDialog());
                if (!mounted) return;
                if (client == null) return;
                final packages = await nav.push<dynamic>(
                  MaterialPageRoute(builder: (_) => PackagePickerScreen(client: client)),
                );
                if (!mounted) return;
                if (packages == null) return;
                // calculate total safely
                double total = 0.0;
                if (packages is Map) {
                  for (final entry in packages.entries) {
                    final key = entry.key;
                    final val = entry.value;
                    double price = 0.0;
                    if (key is Package) {
                      price = key.price;
                    } else if (key is Map && key['price'] != null) {
                      price = (key['price'] as num).toDouble();
                    }
                    final int qty = val is int ? val : int.tryParse(val.toString()) ?? 0;
                    total += price * qty;
                  }
                }
                final saved = await nav.push<bool?>(
                  MaterialPageRoute(
                    builder: (_) => QuoteOverviewScreen(client: client, total: total, packages: packages),
                  ),
                );
                if (saved == true && mounted) setState(() {});
              },
              tooltip: 'Create quote',
              child: const Icon(Icons.add),
            ),
          );
  }
}

class QuoteList extends StatefulWidget {
  const QuoteList({super.key});

  @override
  State<QuoteList> createState() => _QuoteListState();
}

class _QuoteListState extends State<QuoteList> {
  final QuoteTable _table = QuoteTable();
  List<Quote> _quotes = [];
  bool _loading = true;
  String _filter = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  final Map<int, String> _clientNames = {};

  @override
  void initState() {
    super.initState();
    load();
    _restoreState();
    _searchController.addListener(() {
      final v = _searchController.text.trim();
      if (v != _filter) setState(() => _filter = v);
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        final prefs = await SharedPreferences.getInstance();
        if (v.isEmpty) {
          await prefs.remove(_QuotePageState._kLastSearchKey);
        } else {
          await prefs.setString(_QuotePageState._kLastSearchKey, v);
        }
      });
    });
  }

  Future<void> _restoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSearch = prefs.getString(_QuotePageState._kLastSearchKey) ?? '';
      if (lastSearch.isNotEmpty) {
        _searchController.text = lastSearch;
        setState(() => _filter = lastSearch);
      }
    } catch (_) {}
  }

  Future<void> load() async {
    setState(() => _loading = true);
    final data = await _table.getAllQuotes();
    if (!mounted) return;
    // also preload client names to avoid many DB calls — use shared cache
    try {
      final clients = await DataCache.instance.getClients();
      _clientNames.clear();
      for (final c in clients) {
        if (c.id != null) _clientNames[c.id!] = '${c.firstName} ${c.lastName}';
      }
    } catch (_) {}
    setState(() {
      _quotes = data;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(() {});
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final filtered = _filter.isEmpty
        ? _quotes
        : _quotes.where((q) => ('Quote #${q.id}'.toLowerCase()).contains(_filter.toLowerCase()) || q.description.toLowerCase().contains(_filter.toLowerCase())).toList();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search quotes by id or description',
              suffixIcon: _filter.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _filter = v.trim()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('No quotes'))
          : ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
                          final q = filtered[index];
                          final clientName = _clientNames[q.clientId] ?? 'Client ${q.clientId}';
                          final title = 'Quote #${q.id} — $clientName';
                          final subtitle = 'Total: ${formatRand(q.totalPrice)} \n${formatDateTime(q.createdAt)}';
                          return SectionCard(
                            elevation: UIStyles.cardElevation,
                            child: ListTile(
                              contentPadding: UIStyles.tilePadding,
                              leading: const Icon(Icons.description_outlined),
                              title: Text(title),
                              subtitle: Text(
                                '${q.description}\n$subtitle',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  tooltip: 'Book from quote',
                                  onPressed: () async {
                                    final nav = Navigator.of(context);
                                    final messenger = ScaffoldMessenger.of(context);
                                    try {
                                      final created = await nav.push<bool>(
                                        MaterialPageRoute(builder: (_) => CreateBookingPage(quote: q)),
                                      );
                                      if (created == true) {
                                        if (mounted) await load();
                                      }
                                    } catch (e) {
                                      messenger.showSnackBar(SnackBar(content: Text('Failed to book: $e')));
                                    }
                                  },
                                ),
                              ]),
                              onTap: () async {
                                final nav = Navigator.of(context);
                                try {
                                  await nav.push(
                                    MaterialPageRoute(builder: (_) => const ManageQuotePage(), settings: RouteSettings(arguments: q)),
                                  );
                                  if (mounted) {
                                      await load();
                                    }
                                } catch (e) {
                                  if (nav.mounted) { ScaffoldMessenger.of(nav.context).showSnackBar(SnackBar(content: Text('Failed to open quote: $e'))); }
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
