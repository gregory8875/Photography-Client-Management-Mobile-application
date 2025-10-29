import 'dart:async';

import 'package:flutter/foundation.dart';
// Shutterbook — Create Quote flow
// Multi-step flow for building a quote (select client, add packages/items,
// review total). Split into small screens in the create/ directory.
import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/client.dart';
import '/data/tables/client_table.dart';
import '../package_picker/package_picker/package_picker_screen.dart';
import '/data/models/package.dart';
import 'package:shutterbook/theme/ui_styles.dart';
import '../overview/quote_overview_screen.dart';
import '../../clients/clients.dart';


class CreateQuotePage extends StatefulWidget {
  const CreateQuotePage({super.key});

  @override
  State<CreateQuotePage> createState() => _CreateQuotePageState();
}

class _CreateQuotePageState extends State<CreateQuotePage> {
  
  List<Client> allClients = [];
  List<Client> suggestions = [];
  String searchText = '';
  final GlobalKey _clientsKey = GlobalKey();

  final TextEditingController myEditor = TextEditingController();
  bool showIcon = false;



  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    final table = ClientTable();
    final data = await table.getAllClients();
    setState(() {
      allClients = data;
    });
    suggestions = data;
  }

  Future<void> reload() async {
   await  _loadClients();
 }

  void _onSearchChanged(String value) {
    setState(() {
      searchText = value;
      suggestions = allClients
          .where(
            (client) =>
                client.firstName.toLowerCase().contains(value.toLowerCase()) ||
                client.lastName.toLowerCase().contains(value.toLowerCase()),
          )
          .toList();

      if (suggestions.isEmpty) {
        showIcon = false;
      }
    });
  }

  void _onTapChange(String searchText) {
    myEditor.text = searchText;
    if (myEditor.text == searchText) {
      showIcon = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UIStyles.accentAppBar(context, const Text('Create Quote'), 3,
      actions: [
        IconButton(
          onPressed: () async {
            final nav = Navigator.of(context);
            final state = _clientsKey.currentState;
            if (state != null) {
              try {
                await (state as dynamic).openAddDialog();
                try {
                  await (state as dynamic).refresh();
                } catch (_) {}
                // Reload the client list after adding from embedded dialog
                await reload();
                return;
              } catch (_) {}
            }
            // Navigate to full ClientsPage
            await nav.push<bool>(
              MaterialPageRoute(
                builder: (_) => const ClientsPage(embedded: false, openAddOnLoad: true)
              )
            );
            // Reload the client list when returning from ClientsPage
            if (mounted) {
              await reload();
            }
          },
          icon: const Icon(Icons.person_add),
        )
  ],),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: myEditor,
              decoration: InputDecoration(
                labelText: 'Search Client',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (showIcon)
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () async {
                          // Open package picker and wait for selected packages
                          final navigator = Navigator.of(context);
                          final packages = await navigator.push<dynamic>(
                            MaterialPageRoute(
                              builder: (context) => PackagePickerScreen(
                                client: Client.fromMap(suggestions[0].toMap()),
                              ),
                            ),
                          );
                          if (packages == null) {
                            return;
                          }
                          if (kDebugMode) debugPrint('CreateQuotePage got packages: ${packages.keys.map((p) => p.name).join(', ')}');
                          // calculate total safely and navigate to overview for confirmation
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
                          final saved = await navigator.push<bool?>(
                            MaterialPageRoute(
                              builder: (context) => QuoteOverviewScreen(client: Client.fromMap(suggestions[0].toMap()), total: total, packages: packages),
                            ),
                          );
                          // if the overview saved the quote, close this create page too
                          if (saved == true) {
                            if (mounted) navigator.pop(true);
                          }
                        },
                      ),
                    if (myEditor.text.isNotEmpty || showIcon)
                      IconButton(
                        onPressed: () {
                          myEditor.text = "";
                          setState(() {
                            showIcon = false;
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ),
              onChanged: _onSearchChanged,
            ),

            Expanded(
              child: allClients.isEmpty
              ?const Center(child: Text('No clients found'))
              :ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final client = suggestions[index];
                  return ListTile(
                    contentPadding: UIStyles.tilePadding,
                    title: Text('${client.firstName} ${client.lastName}'),
                    subtitle: Text(client.email),
                    onTap: () {
                      // Handle client selection
                      if (kDebugMode) {
                        debugPrint(
                          'Selected: ${client.firstName} ${client.lastName}',
                        );
                      }
                      setState(() {
                        searchText = '${client.firstName} ${client.lastName}';
                        _onTapChange(searchText);
                        suggestions = [client];
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
