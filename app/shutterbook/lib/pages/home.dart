// Shutterbook — Home screen
// A simple navigation hub used after login or setup. Keeps the list of
// top-level links to the main app sections.
import 'package:flutter/material.dart';
import 'authentication/models/auth_model.dart';
import 'settings/settings.dart';
import 'package:shutterbook/theme/ui_styles.dart';

class HomeScreen extends StatelessWidget {
  final AuthModel authModel;

  const HomeScreen({super.key, required this.authModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      {'title': 'Dashboard', 'subtitle': 'View bookings dashboard', 'icon': Icons.dashboard, 'route': '/dashboard'},
      {'title': 'Clients', 'subtitle': 'Manage clients and their details', 'icon': Icons.people, 'route': '/clients'},
      {'title': 'Quotes', 'subtitle': 'Create and view quotes', 'icon': Icons.request_quote, 'route': '/quotes'},
      {'title': 'Bookings', 'subtitle': 'Track scheduled sessions', 'icon': Icons.calendar_today, 'route': '/bookings'},
      {'title': 'Inventory', 'subtitle': 'View the items in your inventory', 'icon': Icons.inventory, 'route': '/inventory'},
    ];

    return Scaffold(
      appBar: UIStyles.accentAppBar(context, const Text('Home'), 0, actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(authModel: authModel),
              ),
            );
          },
        ),
      ]),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final it = items[index];
            return Card(
              elevation: UIStyles.cardElevation,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                contentPadding: UIStyles.tilePadding,
                leading: Icon(it['icon'] as IconData, color: theme.colorScheme.primary, size: 28),
                title: Text(it['title'] as String, style: theme.textTheme.titleMedium),
                subtitle: Text(it['subtitle'] as String, style: theme.textTheme.bodyMedium),
                trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                onTap: () => Navigator.pushNamed(context, it['route'] as String),
              ),
            );
          },
        ),
      ),
    );
  }
}
