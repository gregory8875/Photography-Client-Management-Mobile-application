// Shutterbook — client_search_dialog.dart
// Small dialog used across the app to search and pick clients. Also
// contains an inline add-client dialog so users can create and return a
// newly created client without leaving the current flow.
import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/theme/ui_styles.dart';
import 'package:shutterbook/data/tables/client_table.dart';
import 'package:shutterbook/data/services/data_cache.dart';

class ClientSearchDialog extends StatefulWidget {
  const ClientSearchDialog({super.key});

  @override
  State<ClientSearchDialog> createState() => _ClientSearchDialogState();
}

class _ClientSearchDialogState extends State<ClientSearchDialog> {
  List<Client> _all = [];
  List<Client> _filtered = [];
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  _search.addListener(_onChange);
  }

  Future<void> _load() async {
    try {
      final list = await DataCache.instance.getClients();
      if (!mounted) return;
      setState(() {
        _all = list;
        _filtered = List.from(list);
      });
    } catch (_) {}
  }

  void _onChange() {
    final q = _search.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.from(_all);
      } else {
        _filtered = _all.where((c) {
          final full = '${c.firstName} ${c.lastName}'.toLowerCase();
          return full.contains(q) || c.email.toLowerCase().contains(q) || c.phone.toLowerCase().contains(q) || ('${c.id}').contains(q);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _search.removeListener(_onChange);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 600,
        height: 480,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search clients by name, email or phone',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add client'),
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      final created = await showDialog<Client?>(
                        context: context,
                        builder: (context) => _AddClientDialog(),
                      );
                      if (created != null) {
                        // refresh list and return newly created client immediately
                        await _load();
                        if (mounted) nav.pop(created);
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text('No clients'))
                  : ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = _filtered[index];
                        return ListTile(
                          contentPadding: UIStyles.tilePadding,
                          title: Text('${c.firstName} ${c.lastName}'),
                          subtitle: Text('${c.email} • ${c.phone}'),
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddClientDialog extends StatefulWidget {
  @override
  State<_AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<_AddClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final ClientTable _table = ClientTable();

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final client = Client(
      firstName: _first.text.trim(),
      lastName: _last.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim().replaceAll(RegExp(r'\D'), ''),
    );
  await _table.insertClient(client);
  // refresh shared cache and then read cached list to find inserted client
  final insertedList = await DataCache.instance.getClients(forceRefresh: true);
  final found = insertedList.firstWhere((c) => c.email == client.email, orElse: () => client);
    if (!mounted) return;
    Navigator.of(context).pop(found);
  }

  String? _validateNotEmpty(String? v) => v == null || v.trim().isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Client'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _first, decoration: const InputDecoration(labelText: 'First name'), validator: _validateNotEmpty),
              TextFormField(controller: _last, decoration: const InputDecoration(labelText: 'Last name'), validator: _validateNotEmpty),
              TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => _validateNotEmpty(v)),
              TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone'), validator: (v) => _validateNotEmpty(v)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
