import 'dart:async';
import 'package:flutter/foundation.dart';
// Shutterbook — Clients management
// Lists and edits clients. Keep UI logic here; persistence is in
// `data/tables/client_table.dart`.
import 'package:flutter/material.dart';
import '../../data/models/client.dart';
import '../../data/tables/client_table.dart';
import '../../data/services/data_cache.dart';
import '../../data/tables/quote_table.dart';
import '../../data/tables/booking_table.dart';
// Use the app-wide ThemeData instead of creating a local Theme so pages
// remain visually consistent with global styles.
import '../../widgets/section_card.dart';
import 'package:shutterbook/utils/dialogs.dart';
import 'package:shutterbook/theme/ui_styles.dart';
import 'package:shutterbook/theme/app_colors.dart';
import '../bookings/bookings.dart';

class ClientsPage extends StatefulWidget {
  final bool embedded; // when true, return content only (no Scaffold)
  final void Function(Client client)? onViewBookings;
  final void Function(Client client)? onViewQuotes;
  const ClientsPage({super.key, this.embedded = false, this.onViewBookings, this.onViewQuotes, this.openAddOnLoad = false});
  final bool openAddOnLoad;

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final ClientTable _clientTable = ClientTable();
  final QuoteTable _quoteTable = QuoteTable();
  final BookingTable _bookingTable = BookingTable();

  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(_onSearchChanged);
    if (widget.openAddOnLoad) {
      // open add dialog after first frame so page is mounted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _addOrEditClient();
      });
    }
  }

  Future<void> _loadClients() async {
    final clients = await _clientTable.getAllClients();
    setState(() {
      _clients = clients;
      // Apply current search filter (if any) after loading
      _applyFilter();
    });
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filteredClients = List.from(_clients);
    } else {
      _filteredClients = _clients.where((c) {
        final full = '${c.firstName} ${c.lastName}'.toLowerCase();
        return full.contains(q) || c.email.toLowerCase().contains(q) || c.phone.toLowerCase().contains(q) || '${c.id}'.contains(q);
      }).toList();
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() {
        _applyFilter();
      });
    });
  }

  // Public refresh method so parent (DashboardHome) can trigger reload when embedded
  Future<void> refresh() async => _loadClients();

  // Publicly callable method to open the Add Client dialog when embedded
  Future<void> openAddDialog() async => await _addOrEditClient();

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email required';
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Invalid email format';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone required';
    final phoneRegex = RegExp(r'^\d{7,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'\D'), ''))) {
      return 'Phone must be 7-15 digits';
    }
    return null;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showConfirmationDialog(context, title: title, content: content, confirmLabel: 'Confirm', cancelLabel: 'Cancel');
  }

  Future<void> _addOrEditClient({Client? client}) async {
    final firstNameController = TextEditingController(
      text: client?.firstName ?? '',
    );
    final lastNameController = TextEditingController(
      text: client?.lastName ?? '',
    );
    final emailController = TextEditingController(text: client?.email ?? '');
    final phoneController = TextEditingController(text: client?.phone ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Client>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(client == null ? 'Add Client' : 'Edit Client'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'First name required'
                        : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Last name required'
                        : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    validator: _validatePhone,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              if (formKey.currentState?.validate() ?? false) {
                final confirmed = await _showConfirmationDialog(
                  client == null ? 'Add Client' : 'Save Changes',
                  client == null
                      ? 'Are you sure you want to add this client?'
                      : 'Are you sure you want to save changes to this client?',
                );
                if (!confirmed) return;
                final newClient = Client(
                  id: client?.id,
                  firstName: _capitalize(firstNameController.text.trim()),
                  lastName: _capitalize(lastNameController.text.trim()),
                  email: emailController.text.trim().toLowerCase(),
                  phone: phoneController.text.trim().replaceAll(
                    RegExp(r'\D'),
                    '',
                  ),
                );
                if (nav.mounted) nav.pop(newClient);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (client == null) {
        await _clientTable.insertClient(result);
      } else {
        await _clientTable.updateClient(result);
      }
      // Clear shared clients cache so other pages pick up changes
      DataCache.instance.clearClients();
      _loadClients();
    }
  }

  Future<void> _deleteClient(Client client) async {
    final confirmed = await _showConfirmationDialog(
      'Delete Client',
      'Are you sure you want to delete ${client.firstName} ${client.lastName}?',
    );
    if (confirmed && client.id != null) {
      await _clientTable.deleteClient(client.id!);
      DataCache.instance.clearClients();
      _loadClients();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // show client details dialog with actions to view quotes or bookings (shows counts)
  Future<void> _showClientDetails(Client client) async {
    // Show dialog immediately and fetch counts asynchronously to avoid
    // blocking the first frame and causing jank.
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          // local mutable holders for counts; null => loading
          int? quotesCount;
          int? bookingsCount;

          // Kick off async fetch after the first frame of the dialog so the
          // dialog appears immediately and updates when data arrives.
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            try {
              if (client.id != null) {
                final qFut = _quoteTable.getQuotesByClient(client.id!);
                final bFut = _bookingTable.getBookingsByClient(client.id!);
                final results = await Future.wait([qFut, bFut]);
                if (!mounted) return;
                setStateDialog(() {
                  quotesCount = (results[0] as List).length;
                  bookingsCount = (results[1] as List).length;
                });
              } else {
                setStateDialog(() {
                  quotesCount = 0;
                  bookingsCount = 0;
                });
              }
            } catch (e) {
              if (kDebugMode) debugPrint('Error fetching client counts: $e');
              try {
                setStateDialog(() {
                  quotesCount = 0;
                  bookingsCount = 0;
                });
              } catch (_) {}
            }
          });

          return AlertDialog(
            title: Row(
              children: [
                Expanded(child: Text('${client.firstName} ${client.lastName}')),
                // overflow menu in the title (top-right) for less-accessible destructive actions
                PopupMenuButton<int>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (v) async {
                    // close details dialog first so subsequent flows use root navigator context
                    Navigator.pop(context);
                    if (v == 1) {
                      await _addOrEditClient(client: client);
                    } else if (v == 2) {
                      await _deleteClient(client);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<int>(value: 1, child: Text('Edit')),
                    PopupMenuItem<int>(
                      value: 2,
                      child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  ],
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${client.email}'),
                const SizedBox(height: 8),
                Text('Phone: ${client.phone}'),
                const SizedBox(height: 12),
                Row(children: [
                  const Text('Quotes: '),
                  if (quotesCount == null) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) else Text('$quotesCount'),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Text('Bookings: '),
                  if (bookingsCount == null) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) else Text('$bookingsCount'),
                ]),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  // Delegate to parent's onViewQuotes if available so we don't push separate views
                  if (widget.onViewQuotes != null) {
                    try {
                      widget.onViewQuotes!(client);
                      return;
                    } catch (_) {}
                  }
                  // fallback to opening full Quotes page
                  Navigator.pushNamed(nav.context, '/quotes', arguments: client);
                },
                child: const Text('View Quotes'),
              ),
              ElevatedButton(
                onPressed: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  // Delegate to parent's onViewBookings if available so we don't push separate views
                  if (widget.onViewBookings != null) {
                    try {
                      widget.onViewBookings!(client);
                    } catch (_) {
                      // fallback to opening full Bookings page
                      Navigator.push(nav.context, MaterialPageRoute(builder: (_) => BookingsPage(initialClient: client)));
                    }
                  } else {
                    Navigator.push(nav.context, MaterialPageRoute(builder: (_) => BookingsPage(initialClient: client)));
                  }
                },
                child: const Text('View Bookings'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pageBody = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                    : null,
                hintText: 'Search clients by name, email or phone',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding: UIStyles.tilePadding,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _filteredClients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final client = _filteredClients[index];
                return SectionCard(
                  child: ListTile(
                    contentPadding: UIStyles.tilePadding,
                    onTap: () => _showClientDetails(client),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        client.firstName.isNotEmpty ? client.firstName[0].toUpperCase() : '?',
                        style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ),
                    title: Text('${client.firstName} ${client.lastName}'),
                    subtitle: Text('${client.email} • ${client.phone}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _addOrEditClient(client: client),
                          tooltip: 'Edit',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return pageBody;

    final tabColor = AppColors.colorForIndex(context, 2);
    final onColor = tabColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Scaffold(
      appBar: UIStyles.accentAppBar(context, const Text('Clients'), 2),
      body: pageBody,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditClient(),
        tooltip: 'Add Client',
        backgroundColor: tabColor,
        foregroundColor: onColor,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
