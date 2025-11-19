import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/models/package.dart';
import 'package:shutterbook/pages/quotes/package_picker/package_add/package_add.dart';
import 'package:shutterbook/pages/quotes/package_picker/package_picker/package_picker.dart';
import 'package:shutterbook/pages/quotes/overview/quote_overview_screen.dart';
import 'package:shutterbook/theme/ui_styles.dart';

class PackagePickerScreen extends StatefulWidget {
  final Client client;

  const PackagePickerScreen({super.key, required this.client});

  @override
  State<PackagePickerScreen> createState() => _PackagePickerScreenState();
}

class _PackagePickerScreenState extends State<PackagePickerScreen> {
  Map<Package, int> _selectedPackages = {};
  final GlobalKey<PackagePickerState> _packagePickerKey = GlobalKey<PackagePickerState>();

  void _onSelectionChanged(Map<Package, int> selectedPackages) {
    setState(() {
      _selectedPackages = selectedPackages;
    });
    debugPrint('Selected packages: ${selectedPackages.keys.map((p) => p.name).join(', ')}');
  }

  void _navigateToOverview() {
    if (_selectedPackages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one package')),
      );
      return;
    }

    final total = _selectedPackages.entries
        .fold(0.0, (sum, entry) => sum + (entry.key.price * entry.value));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteOverviewScreen(
          client: widget.client,
          total: total,
          packages: _selectedPackages,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
      appBar: UIStyles.accentAppBar(context, const Text('Pick Packages'), 3,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            },
            icon: const Icon(Icons.home),
          ),
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context)=> const PackageAdd())
              );
              // Reload the package picker when returning
              if (mounted) {
                _packagePickerKey.currentState?.reload();
              }
            },
            icon: const Icon(Icons.indeterminate_check_box_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: PackagePicker(
                key: _packagePickerKey,
                onSelectionChanged: _onSelectionChanged,
                client: widget.client,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.00,16.00,16.00,32.00),
              child: ElevatedButton(
                onPressed: _navigateToOverview,
                style: _selectedPackages.isEmpty ? UIStyles.primaryButtonGrey(context).copyWith(minimumSize: WidgetStatePropertyAll(const Size(double.infinity,50))): UIStyles.primaryButton(context).copyWith(minimumSize: WidgetStatePropertyAll(const Size(double.infinity,50))),
                child: Text(
                  _selectedPackages.isEmpty 
                    ? 'Please select a package first' 
                    : 'Continue (${_selectedPackages.length} package${_selectedPackages.length != 1 ? 's' : ''} selected)'
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}