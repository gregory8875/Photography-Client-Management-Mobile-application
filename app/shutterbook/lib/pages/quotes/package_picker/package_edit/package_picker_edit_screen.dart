import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/package.dart';
import 'package:shutterbook/pages/quotes/package_picker/package_add/package_add.dart';
import 'package:shutterbook/pages/quotes/package_picker/package_edit/package_picker_edit.dart';
import 'package:shutterbook/pages/quotes/overview/quote_overview_edit_screen.dart';
import 'package:shutterbook/theme/ui_styles.dart';

class PackagePickerEditScreen extends StatefulWidget {
  final int quoteNum;
  

  const PackagePickerEditScreen({super.key, required this.quoteNum});

  @override
  State<PackagePickerEditScreen> createState() => _PackagePickerEditScreenState();
}

class _PackagePickerEditScreenState extends State<PackagePickerEditScreen> {
  final GlobalKey<PackagePickerEditState> _packagePickerEditKey = GlobalKey<PackagePickerEditState>();
  Map<Package, int> _selectedPackages = {};

  void _onSelectionChanged(Map<Package, int> selectedPackages) {
    setState(() {
      _selectedPackages = selectedPackages;
    });
    debugPrint('Selected packages: ${selectedPackages.keys.map((p) => p.name).join(', ')}');
  }

  void _navigateToOverview() {
    final state = _packagePickerEditKey.currentState;
    if (state == null) return;

    final selectedPackages = state.selectedPackages;
    if (selectedPackages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one package')),
      );
      return;
    }

    final total = state.totalPrice;
    final clientName = state.clientName;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteOverviewEditScreen(
          total: total,
          packages: selectedPackages,
          quoteNum: widget.quoteNum,
          clientName: clientName,
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
                _packagePickerEditKey.currentState?.reload();
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
              child: PackagePickerEdit(
                key: _packagePickerEditKey,
                onSelectionChanged: _onSelectionChanged,
                quoteNum: widget.quoteNum,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _navigateToOverview,
                style: UIStyles.primaryButton(context).copyWith(minimumSize: WidgetStatePropertyAll(const Size(double.infinity,50))),
                child: Text(
                  _selectedPackages.isEmpty 
                    ? 'Continue' 
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